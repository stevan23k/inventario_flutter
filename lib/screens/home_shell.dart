import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'productos_screen.dart';
import 'proveedores_screen.dart';

/// Contenedor principal con navegación inferior entre las tres secciones.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  void _seleccionar(int indice) {
    if (indice == _indice) return;
    setState(() => _indice = indice);
  }

  @override
  Widget build(BuildContext context) {
    // Al cambiar de pestaña se crea de nuevo la pantalla para que las
    // consultas se refresquen con la información más reciente.
    final Widget pagina = switch (_indice) {
      0 => DashboardScreen(
        onIrAProductos: () => _seleccionar(1),
        onIrAProveedores: () => _seleccionar(2),
      ),
      1 => const ProductosScreen(),
      _ => const ProveedoresScreen(),
    };

    return Scaffold(
      body: pagina,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _seleccionar,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Proveedores',
          ),
        ],
      ),
    );
  }
}
