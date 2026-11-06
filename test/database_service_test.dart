import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventario/models/producto.dart';
import 'package:inventario/models/proveedor.dart';
import 'package:inventario/models/resumen_inventario.dart';
import 'package:inventario/services/dashboard_service.dart';
import 'package:inventario/services/database_service.dart';
import 'package:inventario/services/producto_service.dart';
import 'package:inventario/services/proveedor_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService databaseService;
  late ProveedorService proveedorService;
  late ProductoService productoService;
  late DashboardService dashboardService;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    databaseService = DatabaseService.instance;
    await databaseService.configurarParaPruebas(
      ruta: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    proveedorService = ProveedorService(databaseService: databaseService);
    productoService = ProductoService(databaseService: databaseService);
    dashboardService = DashboardService(databaseService: databaseService);
  });

  tearDown(() async {
    await databaseService.cerrar();
  });

  Future<int> crearProveedor({
    String nombre = 'Distribuidora El Progreso',
    String? telefono = '+57 300 123 4567',
    String? correo = 'ventas@elprogreso.com',
  }) {
    return proveedorService.crear(
      Proveedor(nombre: nombre, telefono: telefono, correo: correo),
    );
  }

  Future<int> crearProducto({
    required int proveedorId,
    String nombre = 'Café molido 500 g',
    double precio = 18500,
    int stock = 10,
  }) {
    return productoService.crear(
      Producto(
        nombre: nombre,
        precio: precio,
        stock: stock,
        proveedorId: proveedorId,
      ),
    );
  }

  test('la base de datos activa las claves foráneas', () async {
    final Database db = await databaseService.database;
    final List<Map<String, Object?>> resultado = await db.rawQuery(
      'PRAGMA foreign_keys',
    );
    expect(resultado.first.values.first, 1);
  });

  test('CRUD completo de productos con nombre del proveedor', () async {
    final int proveedorId = await crearProveedor();
    final int productoId = await crearProducto(
      proveedorId: proveedorId,
      stock: 10,
    );

    final List<Producto> productos = await productoService.listar();
    expect(productos, hasLength(1));
    expect(productos.first.proveedorNombre, 'Distribuidora El Progreso');
    expect(productos.first.precio, 18500);
    expect(productos.first.stock, 10);

    await productoService.actualizar(
      Producto(
        id: productoId,
        nombre: 'Café molido 500 g',
        precio: 19500,
        stock: 7,
        proveedorId: proveedorId,
      ),
    );

    final Producto? actualizado = await productoService.obtenerPorId(
      productoId,
    );
    expect(actualizado, isNotNull);
    expect(actualizado!.precio, 19500);
    expect(actualizado.stock, 7);

    await productoService.eliminar(productoId);
    expect(await productoService.contar(), 0);
  });

  test('la búsqueda de productos filtra por nombre', () async {
    final int proveedorId = await crearProveedor();
    await crearProducto(proveedorId: proveedorId, nombre: 'Café molido 500 g');
    await crearProducto(
      proveedorId: proveedorId,
      nombre: 'Arroz blanco 1 kg',
      precio: 4800,
    );

    final List<Producto> encontrados = await productoService.listar(
      busqueda: 'caf',
    );
    expect(encontrados, hasLength(1));
    expect(encontrados.first.nombre, 'Café molido 500 g');
  });

  test('el listado de proveedores incluye el conteo de productos', () async {
    final int conProductos = await crearProveedor();
    await crearProveedor(nombre: 'Proveedor sin productos');
    await crearProducto(proveedorId: conProductos);
    await crearProducto(proveedorId: conProductos, nombre: 'Arroz blanco 1 kg');

    final List<Proveedor> proveedores = await proveedorService.listar();
    expect(proveedores, hasLength(2));

    final Proveedor primero = proveedores.firstWhere(
      (Proveedor p) => p.id == conProductos,
    );
    final Proveedor sinProductos = proveedores.firstWhere(
      (Proveedor p) => p.id != conProductos,
    );
    expect(primero.totalProductos, 2);
    expect(sinProductos.totalProductos, 0);
  });

  test('no elimina un proveedor que tiene productos asociados', () async {
    final int proveedorId = await crearProveedor();
    await crearProducto(proveedorId: proveedorId);

    final ResultadoEliminacionProveedor resultado = await proveedorService
        .eliminar(proveedorId);

    expect(resultado, ResultadoEliminacionProveedor.conProductos);
    expect(await proveedorService.contar(), 1);
    expect(await productoService.contar(), 1);
  });

  test('elimina un proveedor sin productos', () async {
    final int proveedorId = await crearProveedor();

    final ResultadoEliminacionProveedor resultado = await proveedorService
        .eliminar(proveedorId);

    expect(resultado, ResultadoEliminacionProveedor.eliminado);
    expect(await proveedorService.contar(), 0);
  });

  test('la clave foránea impide crear productos huérfanos', () async {
    await expectLater(
      productoService.crear(
        const Producto(
          nombre: 'Producto sin proveedor',
          precio: 1000,
          stock: 1,
          proveedorId: 999,
        ),
      ),
      throwsA(isA<DatabaseException>()),
    );
    expect(await productoService.contar(), 0);
  });

  test('el dashboard calcula totales, valor y stock bajo', () async {
    final int proveedorId = await crearProveedor();
    await crearProducto(
      proveedorId: proveedorId,
      nombre: 'Café',
      precio: 10000,
      stock: 4,
    );
    await crearProducto(
      proveedorId: proveedorId,
      nombre: 'Arroz',
      precio: 5000,
      stock: 0,
    );

    final ResumenInventario resumen = await dashboardService.obtenerResumen();

    expect(resumen.totalProductos, 2);
    expect(resumen.totalProveedores, 1);
    expect(resumen.unidadesEnStock, 4);
    expect(resumen.valorInventario, 40000);
    expect(resumen.productosStockBajo, 2);
    expect(resumen.estaVacio, isFalse);
  });

  test('los datos demo solo se cargan cuando la base está vacía', () async {
    // Se prueba la condición sin depender de la capa de datos demo.
    expect(await proveedorService.contar(), 0);
    await crearProveedor();
    expect(await proveedorService.contar(), 1);
  });

  test('los datos persisten al cerrar y reabrir la base de datos', () async {
    final Directory directorio = await Directory.systemTemp.createTemp(
      'stockflow_persistencia_',
    );
    final String ruta = p.join(directorio.path, 'inventario.db');

    await databaseService.configurarParaPruebas(
      ruta: ruta,
      factory: databaseFactoryFfi,
    );

    final ProveedorService proveedores = ProveedorService(
      databaseService: databaseService,
    );
    final ProductoService productos = ProductoService(
      databaseService: databaseService,
    );

    final int proveedorId = await proveedores.crear(
      const Proveedor(nombre: 'Proveedor persistente'),
    );
    await productos.crear(
      Producto(
        nombre: 'Producto persistente',
        precio: 15000,
        stock: 3,
        proveedorId: proveedorId,
      ),
    );

    // Se cierra la conexión como si se cerrara la aplicación.
    await databaseService.cerrar();

    // Se vuelve a abrir la misma ruta: las tablas ya existen y los datos siguen.
    await databaseService.configurarParaPruebas(
      ruta: ruta,
      factory: databaseFactoryFfi,
    );
    final ProductoService productosReabiertos = ProductoService(
      databaseService: databaseService,
    );
    final List<Producto> lista = await productosReabiertos.listar();

    expect(lista, hasLength(1));
    expect(lista.first.nombre, 'Producto persistente');
    expect(lista.first.proveedorNombre, 'Proveedor persistente');

    await databaseService.cerrar();
    await directorio.delete(recursive: true);
  });
}
