import 'package:intl/intl.dart';

final NumberFormat _formatoMoneda = NumberFormat.currency(
  locale: 'es',
  symbol: '\$',
  decimalDigits: 2,
);

/// Formatea un valor monetario, por ejemplo: `$ 18.500,00`.
String formatearMoneda(num valor) => _formatoMoneda.format(valor);

/// Devuelve las iniciales de un nombre para usarlas en avatares.
String inicialesDe(String nombre) {
  final List<String> partes = nombre
      .trim()
      .split(RegExp(r'\s+'))
      .where((String parte) => parte.isNotEmpty)
      .toList();

  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
  return (partes.first.substring(0, 1) + partes[1].substring(0, 1))
      .toUpperCase();
}
