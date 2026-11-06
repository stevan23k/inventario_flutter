import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Muestra un mensaje breve en la parte inferior de la pantalla.
void mostrarMensaje(
  BuildContext context,
  String mensaje, {
  bool esError = false,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: esError
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFF86EFAC),
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje)),
          ],
        ),
      ),
    );
}

/// Diálogo de confirmación reutilizable para acciones destructivas.
Future<bool> confirmarAccion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String textoConfirmar = 'Eliminar',
  String textoCancelar = 'Cancelar',
  IconData icono = Icons.delete_outline_rounded,
  bool destructiva = true,
}) async {
  final bool? respuesta = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      final Color color = destructiva
          ? AppColors.danger
          : AppColors.primaryLight;
      final Color fondo = destructiva
          ? AppColors.dangerLight
          : AppColors.primaryLight.withValues(alpha: 0.12);

      return AlertDialog(
        icon: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
          child: Icon(icono, color: color, size: 28),
        ),
        title: Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Text(textoCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: color,
              foregroundColor: destructiva
                  ? Colors.white
                  : AppColors.primaryDark,
            ),
            child: Text(textoConfirmar),
          ),
        ],
      );
    },
  );
  return respuesta ?? false;
}

/// Diálogo informativo para explicar por qué una acción no es posible.
Future<void> mostrarDialogoInformativo(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  IconData icono = Icons.info_outline_rounded,
  Color color = AppColors.primaryLight,
  String textoBoton = 'Entendido',
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        icon: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: color, size: 28),
        ),
        title: Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              backgroundColor: color,
              foregroundColor: color == AppColors.danger
                  ? Colors.white
                  : AppColors.primaryDark,
            ),
            child: Text(textoBoton),
          ),
        ],
      );
    },
  );
}
