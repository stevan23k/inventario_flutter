import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario/main.dart';
import 'package:inventario/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    await DatabaseService.instance.configurarParaPruebas(
      ruta: inMemoryDatabasePath,
      factory: databaseFactoryFfiNoIsolate,
    );
  });

  tearDown(() async {
    await DatabaseService.instance.cerrar();
  });

  /// Deja correr las consultas reales de SQLite y luego estabiliza la UI.
  Future<void> esperar(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('flujo completo: proveedor y producto desde la interfaz', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const InventarioApp());
    await esperar(tester);

    // Dashboard con estado vacío.
    expect(find.text('StockFlow'), findsOneWidget);
    expect(find.text('Todavía no hay registros'), findsOneWidget);

    // Navegar a proveedores desde la barra inferior.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Proveedores'),
      ),
    );
    await esperar(tester);
    expect(find.text('Aún no hay proveedores'), findsOneWidget);

    // Crear proveedor.
    await tester.tap(find.text('Agregar proveedor'));
    await esperar(tester);
    expect(find.text('Nuevo proveedor'), findsOneWidget);

    final Finder camposProveedor = find.byType(TextFormField);
    await tester.enterText(camposProveedor.at(0), 'Distribuidora El Progreso');
    await tester.enterText(camposProveedor.at(1), '+57 300 123 4567');
    await tester.enterText(camposProveedor.at(2), 'ventas@elprogreso.com');
    await tester.tap(find.text('Guardar proveedor'));
    await esperar(tester);

    expect(find.text('Distribuidora El Progreso'), findsOneWidget);
    expect(find.text('0 productos'), findsOneWidget);

    // Navegar a productos y crear uno asociado al proveedor.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Productos'),
      ),
    );
    await esperar(tester);
    expect(find.text('Aún no hay productos'), findsOneWidget);

    await tester.tap(find.text('Agregar producto'));
    await esperar(tester);
    expect(find.text('Nuevo producto'), findsOneWidget);

    final Finder camposProducto = find.byType(TextFormField);
    await tester.enterText(camposProducto.at(0), 'Café molido 500 g');
    await tester.enterText(camposProducto.at(1), '18500');
    await tester.enterText(camposProducto.at(2), '24');

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Distribuidora El Progreso').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar producto'));
    await esperar(tester);

    // El listado usa INNER JOIN y muestra el nombre del proveedor.
    expect(find.text('Café molido 500 g'), findsOneWidget);
    expect(find.text('Distribuidora El Progreso'), findsOneWidget);
    expect(find.text('24 uds'), findsOneWidget);
    expect(find.text('1 producto encontrado'), findsOneWidget);

    // Editar el producto y verificar la actualización.
    await tester.tap(find.text('Café molido 500 g'));
    await esperar(tester);
    expect(find.text('Editar producto'), findsOneWidget);

    final Finder camposEdicion = find.byType(TextFormField);
    await tester.enterText(camposEdicion.at(2), '5');
    await tester.tap(find.text('Guardar cambios'));
    await esperar(tester);
    expect(find.text('5 uds'), findsOneWidget);

    // El proveedor no se puede eliminar mientras tenga productos.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Proveedores'),
      ),
    );
    await esperar(tester);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('No se puede eliminar'), findsOneWidget);
    expect(find.textContaining('producto asociado'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('Distribuidora El Progreso'), findsOneWidget);

    // Eliminar el producto y luego el proveedor.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Productos'),
      ),
    );
    await esperar(tester);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await esperar(tester);
    expect(find.text('Aún no hay productos'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Proveedores'),
      ),
    );
    await esperar(tester);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await esperar(tester);
    expect(find.text('Aún no hay proveedores'), findsOneWidget);

    // El dashboard refleja los nuevos totales.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Inicio'),
      ),
    );
    await esperar(tester);

    expect(find.text('Todavía no hay registros'), findsOneWidget);
  });
}
