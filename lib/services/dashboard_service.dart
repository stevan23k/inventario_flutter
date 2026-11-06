import 'package:sqflite/sqflite.dart';

import '../models/panel_inventario.dart';
import '../models/producto.dart';
import '../models/proveedor.dart';
import '../models/resumen_inventario.dart';
import 'database_service.dart';
import 'producto_service.dart';
import 'proveedor_service.dart';

/// Consultas agregadas para las tarjetas del dashboard.
class DashboardService {
  DashboardService({
    DatabaseService? databaseService,
    ProductoService? productoService,
    ProveedorService? proveedorService,
  }) : _databaseService = databaseService ?? DatabaseService.instance,
       _productoService =
           productoService ?? ProductoService(databaseService: databaseService),
       _proveedorService =
           proveedorService ??
           ProveedorService(databaseService: databaseService);

  final DatabaseService _databaseService;
  final ProductoService _productoService;
  final ProveedorService _proveedorService;

  Future<ResumenInventario> obtenerResumen() async {
    final Database db = await _databaseService.database;
    final List<Map<String, Object?>> filas = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM ${DatabaseService.tablaProductos})
          AS total_productos,
        (SELECT COUNT(*) FROM ${DatabaseService.tablaProveedores})
          AS total_proveedores,
        (SELECT COALESCE(SUM(stock), 0) FROM ${DatabaseService.tablaProductos})
          AS unidades_en_stock,
        (SELECT COALESCE(SUM(precio * stock), 0)
          FROM ${DatabaseService.tablaProductos})
          AS valor_inventario,
        (SELECT COUNT(*) FROM ${DatabaseService.tablaProductos}
          WHERE stock <= 5)
          AS productos_stock_bajo
    ''');

    return filas.isEmpty
        ? ResumenInventario.vacio
        : ResumenInventario.fromMap(filas.first);
  }

  /// Totales y una vista previa limitada de productos y proveedores.
  Future<PanelInventario> obtenerPanel({int limite = 3}) async {
    final Future<ResumenInventario> resumenFuture = obtenerResumen();
    final Future<List<Producto>> productosFuture = _productoService.listar(
      limite: limite,
    );
    final Future<List<Proveedor>> proveedoresFuture = _proveedorService.listar(
      limite: limite,
    );

    return PanelInventario(
      resumen: await resumenFuture,
      productos: await productosFuture,
      proveedores: await proveedoresFuture,
    );
  }
}
