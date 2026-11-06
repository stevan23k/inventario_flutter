import 'dart:async';

import 'package:flutter/material.dart';

import '../models/proveedor.dart';
import '../routes/app_routes.dart';
import '../services/proveedor_service.dart';
import '../theme/app_theme.dart';
import '../utils/mensajes.dart';
import '../widgets/campo_busqueda.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/tarjeta_proveedor.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final ProveedorService _proveedorService = ProveedorService();
  final TextEditingController _busquedaController = TextEditingController();

  Timer? _debounce;
  late Future<List<Proveedor>> _future;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _future = _proveedorService.listar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busquedaController.dispose();
    super.dispose();
  }

  void _buscar(String texto) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() {
        _busqueda = texto;
        _future = _proveedorService.listar(busqueda: texto);
      });
    });
  }

  Future<void> _recargar() async {
    final Future<List<Proveedor>> future = _proveedorService.listar(
      busqueda: _busqueda,
    );
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {
      // El FutureBuilder muestra el estado de error.
    }
  }

  Future<void> _abrirFormulario({Proveedor? proveedor}) async {
    final Proveedor? resultado = await Navigator.of(context)
        .pushNamed<Proveedor?>(
          AppRoutes.proveedorFormulario,
          arguments: proveedor,
        );

    if (resultado == null || !mounted) return;

    mostrarMensaje(
      context,
      proveedor == null
          ? 'Proveedor creado correctamente.'
          : 'Proveedor actualizado correctamente.',
    );
    await _recargar();
  }

  Future<void> _eliminar(Proveedor proveedor) async {
    final int? id = proveedor.id;
    if (id == null) return;

    // Se avisa desde el inicio para evitar que el usuario llegue al diálogo
    // de confirmación y luego reciba un error.
    if (proveedor.totalProductos > 0) {
      await mostrarDialogoInformativo(
        context,
        titulo: 'No se puede eliminar',
        mensaje:
            '"${proveedor.nombre}" tiene ${proveedor.totalProductos} '
            '${proveedor.totalProductos == 1 ? 'producto asociado' : 'productos asociados'}. '
            'Reasigna o elimina esos productos primero para conservar la '
            'integridad de los datos.',
        icono: Icons.link_off_rounded,
        color: AppColors.warning,
      );
      return;
    }

    final bool confirmado = await confirmarAccion(
      context,
      titulo: 'Eliminar proveedor',
      mensaje:
          '¿Seguro que deseas eliminar a "${proveedor.nombre}"? Esta acción no se puede deshacer.',
    );
    if (!confirmado || !mounted) return;

    try {
      final ResultadoEliminacionProveedor resultado = await _proveedorService
          .eliminar(id);
      if (!mounted) return;

      switch (resultado) {
        case ResultadoEliminacionProveedor.eliminado:
          mostrarMensaje(context, 'Proveedor eliminado correctamente.');
          await _recargar();
          break;
        case ResultadoEliminacionProveedor.conProductos:
          await mostrarDialogoInformativo(
            context,
            titulo: 'No se puede eliminar',
            mensaje:
                'El proveedor tiene productos asociados. Elimina o reasigna '
                'esos productos antes de borrarlo.',
            icono: Icons.link_off_rounded,
            color: AppColors.warning,
          );
          break;
        case ResultadoEliminacionProveedor.noEncontrado:
          mostrarMensaje(
            context,
            'El proveedor ya no existe en la base de datos.',
            esError: true,
          );
          await _recargar();
          break;
      }
    } catch (_) {
      if (!mounted) return;
      mostrarMensaje(
        context,
        'No se pudo eliminar el proveedor. Intenta de nuevo.',
        esError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        actions: [
          IconButton(
            tooltip: 'Actualizar listado',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo proveedor'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: CampoBusqueda(
              controller: _busquedaController,
              onChanged: _buscar,
              hint: 'Buscar proveedor por nombre...',
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Proveedor>>(
              future: _future,
              builder: (BuildContext context, AsyncSnapshot<List<Proveedor>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return RefreshIndicator(
                    onRefresh: _recargar,
                    color: AppColors.accent,
                    child: EstadoError(
                      mensaje: 'No se pudieron consultar los proveedores de la base de datos.',
                      onReintentar: _recargar,
                    ),
                  );
                }

                final List<Proveedor> proveedores = snapshot.data ?? const [];

                if (proveedores.isEmpty) {
                  final bool hayBusqueda = _busqueda.trim().isNotEmpty;
                  return RefreshIndicator(
                    onRefresh: _recargar,
                    color: AppColors.accent,
                    child: EstadoVacio(
                      icono: hayBusqueda
                          ? Icons.search_off_rounded
                          : Icons.storefront_outlined,
                      titulo: hayBusqueda
                          ? 'Sin resultados'
                          : 'Aún no hay proveedores',
                      mensaje: hayBusqueda
                          ? 'No encontramos proveedores que coincidan con "${_busqueda.trim()}".'
                          : 'Registra a quién le compras tus productos para poder asociarlos.',
                      etiquetaBoton: hayBusqueda
                          ? 'Limpiar búsqueda'
                          : 'Agregar proveedor',
                      onBoton: hayBusqueda
                          ? () {
                              _busquedaController.clear();
                              _buscar('');
                            }
                          : () => _abrirFormulario(),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _recargar,
                  color: AppColors.accent,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 96),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: proveedores.length + 1,
                    separatorBuilder: (BuildContext context, int index) =>
                        SizedBox(height: index == 0 ? 8 : 12),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return Text(
                          proveedores.length == 1
                              ? '1 proveedor registrado'
                              : '${proveedores.length} proveedores registrados',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        );
                      }

                      final Proveedor proveedor = proveedores[index - 1];
                      return TarjetaProveedor(
                        proveedor: proveedor,
                        onEditar: () => _abrirFormulario(proveedor: proveedor),
                        onEliminar: () => _eliminar(proveedor),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
