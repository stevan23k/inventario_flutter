import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String nombreBaseDatos = 'inventario.db';
  static const int versionBaseDatos = 1;

  static const String tablaProveedores = 'proveedores';
  static const String tablaProductos = 'productos';

  Database? _database;
  Future<Database>? _abriendo;

  String? _rutaPersonalizada;
  DatabaseFactory? _factoryPersonalizada;

  @visibleForTesting
  Future<void> configurarParaPruebas({
    required String ruta,
    DatabaseFactory? factory,
  }) async {
    await cerrar();
    _rutaPersonalizada = ruta;
    _factoryPersonalizada = factory;
  }

  Future<Database> get database async {
    final Database? actual = _database;
    if (actual != null && actual.isOpen) return actual;

    _abriendo ??= _abrirBaseDatos();
    try {
      final Database db = await _abriendo!;
      _database = db;
      return db;
    } finally {
      _abriendo = null;
    }
  }

  Future<Database> _abrirBaseDatos() async {
    final DatabaseFactory factory = _factoryPersonalizada ?? databaseFactory;
    final String ruta =
        _rutaPersonalizada ??
        p.join(await factory.getDatabasesPath(), nombreBaseDatos);

    return factory.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: versionBaseDatos,
        onConfigure: (Database db) async {
          // Requisito: activar las claves foráneas en cada conexión.
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _crearTablas,
      ),
    );
  }

  Future<void> _crearTablas(Database db, int version) async {
    final Batch batch = db.batch();

    batch.execute('''
      CREATE TABLE $tablaProveedores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        correo TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE $tablaProductos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL CHECK (precio > 0),
        stock INTEGER NOT NULL CHECK (stock >= 0),
        proveedor_id INTEGER NOT NULL,
        FOREIGN KEY (proveedor_id)
          REFERENCES $tablaProveedores (id)
          ON UPDATE CASCADE
          ON DELETE RESTRICT
      )
    ''');

    batch.execute(
      'CREATE INDEX idx_productos_proveedor ON $tablaProductos (proveedor_id)',
    );
    batch.execute(
      'CREATE INDEX idx_productos_nombre ON $tablaProductos (nombre)',
    );
    batch.execute(
      'CREATE INDEX idx_proveedores_nombre ON $tablaProveedores (nombre)',
    );

    await batch.commit(noResult: true);
  }

  Future<void> cerrar() async {
    final Database? db = _database;
    _database = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}
