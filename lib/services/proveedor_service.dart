import 'package:sqflite/sqflite.dart';

import '../models/proveedor.dart';
import 'database_service.dart';

enum ResultadoEliminacionProveedor { eliminado, conProductos, noEncontrado }

class ProveedorService {
  ProveedorService({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  static const String _tabla = DatabaseService.tablaProveedores;

  Future<Database> get _db => _databaseService.database;

  Future<int> crear(Proveedor proveedor) async {
    final Database db = await _db;
    return db.insert(_tabla, proveedor.toMap());
  }

  Future<int> actualizar(Proveedor proveedor) async {
    final int? id = proveedor.id;
    if (id == null) {
      throw ArgumentError('El proveedor debe tener un id para actualizarse.');
    }
    final Database db = await _db;
    return db.update(
      _tabla,
      proveedor.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ResultadoEliminacionProveedor> eliminar(int id) async {
    final Database db = await _db;
    return db.transaction((Transaction txn) async {
      final int asociados = await _contarProductos(txn, id);
      if (asociados > 0) {
        return ResultadoEliminacionProveedor.conProductos;
      }

      final int filas = await txn.delete(
        _tabla,
        where: 'id = ?',
        whereArgs: [id],
      );
      return filas > 0
          ? ResultadoEliminacionProveedor.eliminado
          : ResultadoEliminacionProveedor.noEncontrado;
    });
  }

  Future<List<Proveedor>> listar({String? busqueda, int? limite}) async {
    final Database db = await _db;
    final String texto = (busqueda ?? '').trim();
    final bool filtrar = texto.isNotEmpty;

    final List<Object?> argumentos = [if (filtrar) '%$texto%', ?limite];

    final List<Map<String, Object?>> filas = await db.rawQuery('''
      SELECT
        pr.id,
        pr.nombre,
        pr.telefono,
        pr.correo,
        COUNT(p.id) AS total_productos
      FROM ${DatabaseService.tablaProveedores} pr
      LEFT JOIN ${DatabaseService.tablaProductos} p
        ON p.proveedor_id = pr.id
      ${filtrar ? 'WHERE pr.nombre LIKE ?' : ''}
      GROUP BY pr.id, pr.nombre, pr.telefono, pr.correo
      ORDER BY pr.nombre COLLATE NOCASE ASC
      ${limite != null ? 'LIMIT ?' : ''}
      ''', argumentos.isEmpty ? null : argumentos);

    return filas.map(Proveedor.fromMap).toList();
  }

  Future<Proveedor?> obtenerPorId(int id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> filas = await db.rawQuery(
      '''
      SELECT
        pr.id,
        pr.nombre,
        pr.telefono,
        pr.correo,
        COUNT(p.id) AS total_productos
      FROM ${DatabaseService.tablaProveedores} pr
      LEFT JOIN ${DatabaseService.tablaProductos} p
        ON p.proveedor_id = pr.id
      WHERE pr.id = ?
      GROUP BY pr.id, pr.nombre, pr.telefono, pr.correo
      ''',
      [id],
    );
    return filas.isEmpty ? null : Proveedor.fromMap(filas.first);
  }

  Future<int> contarProductos(int proveedorId) async {
    final Database db = await _db;
    return _contarProductos(db, proveedorId);
  }

  Future<int> contar() async {
    final Database db = await _db;
    final int? total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tabla'),
    );
    return total ?? 0;
  }

  Future<int> _contarProductos(
    DatabaseExecutor executor,
    int proveedorId,
  ) async {
    final int? total = Sqflite.firstIntValue(
      await executor.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseService.tablaProductos} '
        'WHERE proveedor_id = ?',
        [proveedorId],
      ),
    );
    return total ?? 0;
  }
}
