import 'package:flutter/material.dart';

import '../models/panel_inventario.dart';
import '../models/producto.dart';
import '../models/proveedor.dart';
import '../models/resumen_inventario.dart';
import '../services/dashboard_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/encabezado_seccion.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onIrAProductos,
    required this.onIrAProveedores,
  });

  final VoidCallback onIrAProductos;
  final VoidCallback onIrAProveedores;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();

  late Future<PanelInventario> _future;

  @override
  void initState() {
    super.initState();
    _future = _dashboardService.obtenerPanel();
  }

  Future<void> _recargar() async {
    final Future<PanelInventario> future = _dashboardService.obtenerPanel();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      body: RefreshIndicator(
        onRefresh: _recargar,
        color: AppColors.accent,
        child: FutureBuilder<PanelInventario>(
          future: _future,
          builder:
              (BuildContext context, AsyncSnapshot<PanelInventario> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 42,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No se pudo cargar el resumen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _recargar,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Reintentar'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final PanelInventario panel =
                    snapshot.data ?? PanelInventario.vacio;
                final ResumenInventario resumen = panel.resumen;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    const Text(
                      'Panel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Resumen general del inventario.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _TarjetaTotal(
                            icono: Icons.inventory_2_outlined,
                            color: AppColors.accent,
                            valor: '${resumen.totalProductos}',
                            etiqueta: 'Productos',
                            onTap: widget.onIrAProductos,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TarjetaTotal(
                            icono: Icons.storefront_outlined,
                            color: AppColors.primaryDark,
                            valor: '${resumen.totalProveedores}',
                            etiqueta: 'Proveedores',
                            onTap: widget.onIrAProveedores,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    EncabezadoSeccion(
                      titulo: 'Productos',
                      accion: 'Ver más',
                      onAccion: widget.onIrAProductos,
                    ),
                    const SizedBox(height: 10),
                    if (panel.productos.isEmpty)
                      _SeccionSinRegistros(
                        icono: Icons.inventory_2_outlined,
                        mensaje: 'Aún no hay productos registrados.',
                        etiquetaBoton: 'Agregar',
                        onTap: widget.onIrAProductos,
                      )
                    else
                      for (int i = 0; i < panel.productos.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _VistaPreviaProducto(
                          producto: panel.productos[i],
                          onTap: widget.onIrAProductos,
                        ),
                      ],
                    const SizedBox(height: 24),
                    EncabezadoSeccion(
                      titulo: 'Proveedores',
                      accion: 'Ver más',
                      onAccion: widget.onIrAProveedores,
                    ),
                    const SizedBox(height: 10),
                    if (panel.proveedores.isEmpty)
                      _SeccionSinRegistros(
                        icono: Icons.storefront_outlined,
                        mensaje: 'Aún no hay proveedores registrados.',
                        etiquetaBoton: 'Agregar',
                        onTap: widget.onIrAProveedores,
                      )
                    else
                      for (int i = 0; i < panel.proveedores.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _VistaPreviaProveedor(
                          proveedor: panel.proveedores[i],
                          onTap: widget.onIrAProveedores,
                        ),
                      ],
                    if (resumen.estaVacio) ...[
                      const SizedBox(height: 24),
                      const _EstadoInicial(),
                    ],
                    const SizedBox(height: 24),
                  ],
                );
              },
        ),
      ),
    );
  }
}

class _TarjetaTotal extends StatelessWidget {
  const _TarjetaTotal({
    required this.icono,
    required this.color,
    required this.valor,
    required this.etiqueta,
    required this.onTap,
  });

  final IconData icono;
  final Color color;
  final String valor;
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                etiqueta,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila compacta de un producto para la vista previa del panel.
class _VistaPreviaProducto extends StatelessWidget {
  const _VistaPreviaProducto({required this.producto, required this.onTap});

  final Producto producto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool agotado = producto.stock == 0;
    final bool bajo = producto.stock <= 5;
    final Color colorStock = agotado
        ? AppColors.danger
        : bajo
        ? AppColors.warning
        : AppColors.textSecondary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _Avatar(
                texto: inicialesDe(producto.nombre),
                icono: Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      producto.proveedorNombre ?? 'Proveedor no disponible',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatearMoneda(producto.precio),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agotado ? 'Agotado' : '${producto.stock} uds',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: colorStock,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila compacta de un proveedor para la vista previa del panel.
class _VistaPreviaProveedor extends StatelessWidget {
  const _VistaPreviaProveedor({required this.proveedor, required this.onTap});

  final Proveedor proveedor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? telefono = proveedor.telefono?.trim();
    final String? correo = proveedor.correo?.trim();
    final String contacto = (telefono != null && telefono.isNotEmpty)
        ? telefono
        : (correo != null && correo.isNotEmpty)
        ? correo
        : 'Sin datos de contacto';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _Avatar(
                texto: inicialesDe(proveedor.nombre),
                icono: Icons.storefront_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proveedor.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contacto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                proveedor.totalProductos == 1
                    ? '1 producto'
                    : '${proveedor.totalProductos} productos',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.texto, required this.icono});

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.primaryLight.withValues(alpha: 0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: texto == '?'
          ? Icon(icono, size: 20, color: AppColors.primaryDark)
          : Text(
              texto,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
    );
  }
}

class _SeccionSinRegistros extends StatelessWidget {
  const _SeccionSinRegistros({
    required this.icono,
    required this.mensaje,
    required this.etiquetaBoton,
    required this.onTap,
  });

  final IconData icono;
  final String mensaje;
  final String etiquetaBoton;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icono, size: 20, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(onPressed: onTap, child: Text(etiquetaBoton)),
        ],
      ),
    );
  }
}

class _EstadoInicial extends StatelessWidget {
  const _EstadoInicial();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Todavía no hay registros',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Crea un proveedor y luego registra sus productos para comenzar '
            'a controlar tu inventario.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
