/// Totales calculados en una sola consulta para el dashboard.
class ResumenInventario {
  final int totalProductos;
  final int totalProveedores;
  final int unidadesEnStock;
  final double valorInventario;
  final int productosStockBajo;

  const ResumenInventario({
    required this.totalProductos,
    required this.totalProveedores,
    required this.unidadesEnStock,
    required this.valorInventario,
    required this.productosStockBajo,
  });

  factory ResumenInventario.fromMap(Map<String, Object?> map) {
    return ResumenInventario(
      totalProductos: (map['total_productos'] as num?)?.toInt() ?? 0,
      totalProveedores: (map['total_proveedores'] as num?)?.toInt() ?? 0,
      unidadesEnStock: (map['unidades_en_stock'] as num?)?.toInt() ?? 0,
      valorInventario: (map['valor_inventario'] as num?)?.toDouble() ?? 0,
      productosStockBajo: (map['productos_stock_bajo'] as num?)?.toInt() ?? 0,
    );
  }

  bool get estaVacio => totalProductos == 0 && totalProveedores == 0;

  static const ResumenInventario vacio = ResumenInventario(
    totalProductos: 0,
    totalProveedores: 0,
    unidadesEnStock: 0,
    valorInventario: 0,
    productosStockBajo: 0,
  );
}
