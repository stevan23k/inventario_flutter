import 'dart:async';

import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../routes/app_routes.dart';
import '../services/producto_service.dart';
import '../theme/app_theme.dart';
import '../utils/mensajes.dart';
import '../widgets/campo_busqueda.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/tarjeta_producto.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ProductoService _productoService = ProductoService();
  final TextEditingController _busquedaController = TextEditingController();

  Timer? _debounce;
  late Future<List<Producto>> _future;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _future = _productoService.listar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busquedaController.dispose();
    super.dispose();
  }

  void _buscar(String texto) {
    _debounce?.cancel();
    // Actualiza el icono de limpiar mientras se espera el debounce.
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() {
        _busqueda = texto;
        _future = _productoService.listar(busqueda: texto);
      });
    });
  }

  Future<void> _recargar() async {
    final Future<List<Producto>> future = _productoService.listar(
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

  Future<void> _abrirFormulario({Producto? producto}) async {
    final Producto? resultado = await Navigator.of(
      context,
    ).pushNamed<Producto?>(AppRoutes.productoFormulario, arguments: producto);

    if (resultado == null || !mounted) return;

    mostrarMensaje(
      context,
      producto == null
          ? 'Producto creado correctamente.'
          : 'Producto actualizado correctamente.',
    );
    await _recargar();
  }

  Future<void> _eliminar(Producto producto) async {
    final int? id = producto.id;
    if (id == null) return;

    final bool confirmado = await confirmarAccion(
      context,
      titulo: 'Eliminar producto',
      mensaje:
          '¿Seguro que deseas eliminar "${producto.nombre}"? Esta acción no se puede deshacer.',
    );
    if (!confirmado || !mounted) return;

    try {
      await _productoService.eliminar(id);
      if (!mounted) return;
      mostrarMensaje(context, 'Producto eliminado correctamente.');
      await _recargar();
    } catch (_) {
      if (!mounted) return;
      mostrarMensaje(
        context,
        'No se pudo eliminar el producto. Intenta de nuevo.',
        esError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
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
        label: const Text('Nuevo producto'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: CampoBusqueda(
              controller: _busquedaController,
              onChanged: _buscar,
              hint: 'Buscar producto por nombre...',
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Producto>>(
              future: _future,
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<Producto>> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return RefreshIndicator(
                        onRefresh: _recargar,
                        color: AppColors.accent,
                        child: EstadoError(
                          mensaje: 'No se pudieron consultar los productos de la base de datos.',
                          onReintentar: _recargar,
                        ),
                      );
                    }

                    final List<Producto> productos = snapshot.data ?? const [];

                    if (productos.isEmpty) {
                      final bool hayBusqueda = _busqueda.trim().isNotEmpty;
                      return RefreshIndicator(
                        onRefresh: _recargar,
                        color: AppColors.accent,
                        child: EstadoVacio(
                          icono: hayBusqueda
                              ? Icons.search_off_rounded
                              : Icons.inventory_2_outlined,
                          titulo: hayBusqueda
                              ? 'Sin resultados'
                              : 'Aún no hay productos',
                          mensaje: hayBusqueda
                              ? 'No encontramos productos que coincidan con "${_busqueda.trim()}".'
                              : 'Registra tu primer producto y asígnalo a uno de tus proveedores.',
                          etiquetaBoton: hayBusqueda
                              ? 'Limpiar búsqueda'
                              : 'Agregar producto',
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
                        itemCount: productos.length + 1,
                        separatorBuilder: (BuildContext context, int index) =>
                            SizedBox(height: index == 0 ? 8 : 12),
                        itemBuilder: (BuildContext context, int index) {
                          if (index == 0) {
                            return Text(
                              productos.length == 1
                                  ? '1 producto encontrado'
                                  : '${productos.length} productos encontrados',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            );
                          }

                          final Producto producto = productos[index - 1];
                          return TarjetaProducto(
                            producto: producto,
                            onEditar: () =>
                                _abrirFormulario(producto: producto),
                            onEliminar: () => _eliminar(producto),
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
