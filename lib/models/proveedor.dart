/// Proveedor de productos.
///
/// [totalProductos] no se almacena en la tabla `proveedores`: se calcula con
/// una consulta `LEFT JOIN` para mostrarlo en el listado.
class Proveedor {
  final int? id;
  final String nombre;
  final String? telefono;
  final String? correo;
  final int totalProductos;

  const Proveedor({
    this.id,
    required this.nombre,
    this.telefono,
    this.correo,
    this.totalProductos = 0,
  });

  factory Proveedor.fromMap(Map<String, Object?> map) {
    return Proveedor(
      id: map['id'] as int?,
      nombre: (map['nombre'] as String?) ?? '',
      telefono: map['telefono'] as String?,
      correo: map['correo'] as String?,
      totalProductos: (map['total_productos'] as num?)?.toInt() ?? 0,
    );
  }

  /// Mapa listo para insertar o actualizar en SQLite.
  ///
  /// El id se omite cuando es null para que AUTOINCREMENT lo genere.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'telefono': _textoONull(telefono),
      'correo': _textoONull(correo),
    };
  }

  Proveedor copyWith({
    int? id,
    String? nombre,
    String? telefono,
    String? correo,
    int? totalProductos,
  }) {
    return Proveedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      totalProductos: totalProductos ?? this.totalProductos,
    );
  }

  static String? _textoONull(String? valor) {
    final String texto = (valor ?? '').trim();
    return texto.isEmpty ? null : texto;
  }
}
