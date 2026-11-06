/// Producto del inventario.
///
/// [proveedorNombre] proviene de la consulta con `INNER JOIN` entre
/// `productos` y `proveedores`; no existe como columna en la tabla.
class Producto {
  final int? id;
  final String nombre;
  final double precio;
  final int stock;
  final int proveedorId;
  final String? proveedorNombre;

  const Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
    required this.proveedorId,
    this.proveedorNombre,
  });

  factory Producto.fromMap(Map<String, Object?> map) {
    return Producto(
      id: map['id'] as int?,
      nombre: (map['nombre'] as String?) ?? '',
      precio: (map['precio'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      proveedorId: (map['proveedor_id'] as num?)?.toInt() ?? 0,
      proveedorNombre: map['proveedor_nombre'] as String?,
    );
  }

  /// Mapa listo para insertar o actualizar en SQLite.
  ///
  /// `proveedor_nombre` se excluye porque solo es un alias de la consulta.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'precio': precio,
      'stock': stock,
      'proveedor_id': proveedorId,
    };
  }

  Producto copyWith({
    int? id,
    String? nombre,
    double? precio,
    int? stock,
    int? proveedorId,
    String? proveedorNombre,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      proveedorId: proveedorId ?? this.proveedorId,
      proveedorNombre: proveedorNombre ?? this.proveedorNombre,
    );
  }

  bool get stockBajo => stock <= 5;
  bool get agotado => stock == 0;
}
