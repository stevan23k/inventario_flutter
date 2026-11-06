import 'package:sqflite/sqflite.dart';

import '../models/producto.dart';
import 'database_service.dart';

class ProductoService {
  ProductoService({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  static const String _tabla = DatabaseService.tablaProductos;

  Future<Database> get _db => _databaseService.database;

  Future<int> crear(Producto producto) async {
    final Database db = await _db;
    return db.insert(_tabla, producto.toMap());
  }

  Future<int> actualizar(Producto producto) async {
    final int? id = producto.id;
    if (id == null) {
      throw ArgumentError('El producto debe tener un id para actualizarse.');
    }
    final Database db = await _db;
    return db.update(
      _tabla,
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminar(int id) async {
    final Database db = await _db;
    return db.delete(_tabla, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Producto>> listar({String? busqueda, int? limite}) async {
    final Database db = await _db;
    final String texto = (busqueda ?? '').trim();
    final bool filtrar = texto.isNotEmpty;

    final List<Object?> argumentos = [if (filtrar) '%$texto%', ?limite];

    final List<Map<String, Object?>> filas = await db.rawQuery('''
      SELECT
        p.id,
        p.nombre,
        p.precio,
        p.stock,
        p.proveedor_id,
        pr.nombre AS proveedor_nombre
      FROM ${DatabaseService.tablaProductos} p
      INNER JOIN ${DatabaseService.tablaProveedores} pr
        ON pr.id = p.proveedor_id
      ${filtrar ? 'WHERE p.nombre LIKE ?' : ''}
      ORDER BY p.nombre COLLATE NOCASE ASC
      ${limite != null ? 'LIMIT ?' : ''}
      ''', argumentos.isEmpty ? null : argumentos);

    return filas.map(Producto.fromMap).toList();
  }

  Future<Producto?> obtenerPorId(int id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> filas = await db.rawQuery(
      '''
      SELECT
        p.id,
        p.nombre,
        p.precio,
        p.stock,
        p.proveedor_id,
        pr.nombre AS proveedor_nombre
      FROM ${DatabaseService.tablaProductos} p
      INNER JOIN ${DatabaseService.tablaProveedores} pr
        ON pr.id = p.proveedor_id
      WHERE p.id = ?
      ''',
      [id],
    );
    return filas.isEmpty ? null : Producto.fromMap(filas.first);
  }

  Future<List<Producto>> listarStockBajo({
    int limite = 5,
    int cantidad = 5,
  }) async {
    final Database db = await _db;
    final List<Map<String, Object?>> filas = await db.rawQuery(
      '''
      SELECT
        p.id,
        p.nombre,
        p.precio,
        p.stock,
        p.proveedor_id,
        pr.nombre AS proveedor_nombre
      FROM ${DatabaseService.tablaProductos} p
      INNER JOIN ${DatabaseService.tablaProveedores} pr
        ON pr.id = p.proveedor_id
      WHERE p.stock <= ?
      ORDER BY p.stock ASC, p.nombre COLLATE NOCASE ASC
      LIMIT ?
      ''',
      [limite, cantidad],
    );
    return filas.map(Producto.fromMap).toList();
  }

  Future<int> contar() async {
    final Database db = await _db;
    final int? total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tabla'),
    );
    return total ?? 0;
  }
}
