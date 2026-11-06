import 'package:flutter/material.dart';

import '../models/proveedor.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';

enum _AccionProveedor { editar, eliminar }

/// Tarjeta del listado de proveedores con sus datos de contacto.
class TarjetaProveedor extends StatelessWidget {
  const TarjetaProveedor({
    super.key,
    required this.proveedor,
    required this.onEditar,
    required this.onEliminar,
  });

  final Proveedor proveedor;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final bool tieneContacto =
        (proveedor.telefono ?? '').isNotEmpty ||
        (proveedor.correo ?? '').isNotEmpty;

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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.16),
                          AppColors.primaryLight.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      inicialesDe(proveedor.nombre),
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
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        proveedor.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<_AccionProveedor>(
                    tooltip: 'Opciones del proveedor',
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onSelected: (_AccionProveedor accion) {
                      switch (accion) {
                        case _AccionProveedor.editar:
                          onEditar();
                          break;
                        case _AccionProveedor.eliminar:
                          onEliminar();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<_AccionProveedor>(
                        value: _AccionProveedor.editar,
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
                      const PopupMenuItem<_AccionProveedor>(
                        value: _AccionProveedor.eliminar,
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
                child: tieneContacto
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((proveedor.telefono ?? '').isNotEmpty)
                            _DatoContacto(
                              icono: Icons.phone_outlined,
                              texto: proveedor.telefono!,
                            ),
                          if ((proveedor.telefono ?? '').isNotEmpty &&
                              (proveedor.correo ?? '').isNotEmpty)
                            const SizedBox(height: 7),
                          if ((proveedor.correo ?? '').isNotEmpty)
                            _DatoContacto(
                              icono: Icons.mail_outline_rounded,
                              texto: proveedor.correo!,
                            ),
                        ],
                      )
                    : const Row(
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Sin datos de contacto',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      size: 13,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      proveedor.totalProductos == 1
                          ? '1 producto'
                          : '${proveedor.totalProductos} productos',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
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

class _DatoContacto extends StatelessWidget {
  const _DatoContacto({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
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
    );
  }
}
