import 'package:flutter_test/flutter_test.dart';
import 'package:inventario/models/producto.dart';
import 'package:inventario/models/proveedor.dart';
import 'package:inventario/models/resumen_inventario.dart';

void main() {
  group('Producto', () {
    test('fromMap lee el alias proveedor_nombre del INNER JOIN', () {
      final Producto producto = Producto.fromMap({
        'id': 1,
        'nombre': 'Café molido 500 g',
        'precio': 18500,
        'stock': 12,
        'proveedor_id': 3,
        'proveedor_nombre': 'Distribuidora El Progreso',
      });

      expect(producto.id, 1);
      expect(producto.nombre, 'Café molido 500 g');
      expect(producto.precio, 18500.0);
      expect(producto.stock, 12);
      expect(producto.proveedorId, 3);
      expect(producto.proveedorNombre, 'Distribuidora El Progreso');
    });

    test('toMap excluye el alias y conserva la clave foránea', () {
      const Producto producto = Producto(
        id: 4,
        nombre: 'Arroz blanco',
        precio: 4800,
        stock: 0,
        proveedorId: 2,
        proveedorNombre: 'Proveedor de prueba',
      );

      expect(producto.toMap(), {
        'id': 4,
        'nombre': 'Arroz blanco',
        'precio': 4800.0,
        'stock': 0,
        'proveedor_id': 2,
      });
      expect(producto.stockBajo, isTrue);
      expect(producto.agotado, isTrue);
    });
  });

  group('Proveedor', () {
    test('fromMap interpreta el conteo del LEFT JOIN', () {
      final Proveedor proveedor = Proveedor.fromMap({
        'id': 2,
        'nombre': 'Lácteos La Pradera',
        'telefono': '+57 310 555 8899',
        'correo': 'contacto@lapradera.co',
        'total_productos': 4,
      });

      expect(proveedor.totalProductos, 4);
      expect(proveedor.telefono, '+57 310 555 8899');
    });

    test('toMap convierte textos vacíos en null', () {
      const Proveedor proveedor = Proveedor(
        nombre: '  Suministros del Norte  ',
        telefono: '   ',
        correo: '',
      );

      final Map<String, Object?> mapa = proveedor.toMap();
      expect(mapa['nombre'], '  Suministros del Norte  ');
      expect(mapa['telefono'], isNull);
      expect(mapa['correo'], isNull);
      expect(mapa.containsKey('id'), isFalse);
    });
  });

  group('ResumenInventario', () {
    test('convierte los valores numéricos de SQLite', () {
      final ResumenInventario resumen = ResumenInventario.fromMap({
        'total_productos': 8,
        'total_proveedores': 3,
        'unidades_en_stock': 120,
        'valor_inventario': 850000.5,
        'productos_stock_bajo': 2,
      });

      expect(resumen.totalProductos, 8);
      expect(resumen.totalProveedores, 3);
      expect(resumen.unidadesEnStock, 120);
      expect(resumen.valorInventario, 850000.5);
      expect(resumen.productosStockBajo, 2);
      expect(resumen.estaVacio, isFalse);
    });
  });
}
