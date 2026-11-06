import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';

enum _AccionProducto { editar, eliminar }

/// Tarjeta del listado de productos con nombre, proveedor, precio y stock.
class TarjetaProducto extends StatelessWidget {
  const TarjetaProducto({
    super.key,
    required this.producto,
    required this.onEditar,
    required this.onEliminar,
  });

  final Producto producto;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEditar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.14),
                          AppColors.primaryLight.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      inicialesDe(producto.nombre),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.storefront_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  producto.proveedorNombre ??
                                      'Proveedor no disponible',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<_AccionProducto>(
                    tooltip: 'Opciones del producto',
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onSelected: (_AccionProducto accion) {
                      switch (accion) {
                        case _AccionProducto.editar:
                          onEditar();
                          break;
                        case _AccionProducto.eliminar:
                          onEliminar();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<_AccionProducto>(
                        value: _AccionProducto.editar,
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 19,
                              color: AppColors.primaryDark,
                            ),
                            SizedBox(width: 10),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<_AccionProducto>(
                        value: _AccionProducto.eliminar,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 19,
                              color: AppColors.danger,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRECIO UNITARIO',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 0.7,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatearMoneda(producto.precio),
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _InsigniaStock(stock: producto.stock),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsigniaStock extends StatelessWidget {
  const _InsigniaStock({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final bool agotado = stock == 0;
    final bool bajo = stock <= 5;

    final Color color = agotado
        ? AppColors.danger
        : bajo
        ? AppColors.warning
        : AppColors.success;
    final Color fondo = agotado
        ? AppColors.dangerLight
        : bajo
        ? AppColors.warningLight
        : AppColors.successLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            agotado
                ? Icons.remove_shopping_cart_outlined
                : bajo
                ? Icons.warning_amber_rounded
                : Icons.inventory_2_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            agotado ? 'Agotado' : '$stock uds',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
