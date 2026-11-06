import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario/models/producto.dart';
import 'package:inventario/theme/app_theme.dart';
import 'package:inventario/widgets/tarjeta_producto.dart';

void main() {
  testWidgets('TarjetaProducto muestra sus datos y permite editar', (
    WidgetTester tester,
  ) async {
    bool editarLlamado = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: TarjetaProducto(
              producto: const Producto(
                id: 1,
                nombre: 'Café molido 500 g',
                precio: 18500,
                stock: 24,
                proveedorId: 1,
                proveedorNombre: 'Distribuidora El Progreso',
              ),
              onEditar: () => editarLlamado = true,
              onEliminar: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Café molido 500 g'), findsOneWidget);
    expect(find.text('Distribuidora El Progreso'), findsOneWidget);
    expect(find.text('24 uds'), findsOneWidget);
    expect(find.textContaining('18.500'), findsOneWidget);

    await tester.tap(find.text('Café molido 500 g'));
    await tester.pump();

    expect(editarLlamado, isTrue);
  });
}
