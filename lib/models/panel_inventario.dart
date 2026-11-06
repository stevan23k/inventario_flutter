import 'producto.dart';
import 'proveedor.dart';
import 'resumen_inventario.dart';

/// Datos que necesita la pantalla principal: totales y una vista previa de
/// los últimos productos y proveedores registrados.
class PanelInventario {
  const PanelInventario({
    required this.resumen,
    required this.productos,
    required this.proveedores,
  });

  final ResumenInventario resumen;
  final List<Producto> productos;
  final List<Proveedor> proveedores;

  static const PanelInventario vacio = PanelInventario(
    resumen: ResumenInventario.vacio,
    productos: <Producto>[],
    proveedores: <Proveedor>[],
  );
}
