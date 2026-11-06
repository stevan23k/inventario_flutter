import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../models/proveedor.dart';
import '../screens/home_shell.dart';
import '../screens/producto_form_screen.dart';
import '../screens/proveedor_form_screen.dart';

/// Rutas con nombre de la aplicación.
///
/// El tipo genérico de cada ruta coincide con el valor que devuelve la
/// pantalla al cerrarse; así `pushNamed<Producto?>` recibe el objeto guardado.
class AppRoutes {
  const AppRoutes._();

  static const String inicio = '/';
  static const String productoFormulario = '/productos/formulario';
  static const String proveedorFormulario = '/proveedores/formulario';

  static Route<dynamic> generarRuta(RouteSettings settings) {
    switch (settings.name) {
      case productoFormulario:
        return MaterialPageRoute<Producto?>(
          builder: (_) =>
              ProductoFormScreen(producto: settings.arguments as Producto?),
          settings: settings,
        );
      case proveedorFormulario:
        return MaterialPageRoute<Proveedor?>(
          builder: (_) =>
              ProveedorFormScreen(proveedor: settings.arguments as Proveedor?),
          settings: settings,
        );
      case inicio:
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeShell(),
          settings: settings,
        );
    }
  }
}
