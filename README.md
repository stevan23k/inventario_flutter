# StockFlow — Inventario con Flutter y SQLite

Aplicación móvil de gestión de inventario para un pequeño negocio. Permite
administrar **proveedores** y **productos** con una relación 1:N, almacenando
toda la información en una base de datos local **SQLite** (sin Firebase ni
servicios en la nube).

## Funcionalidades

- Pantalla principal sencilla con el nombre de la app, el total de productos y
  proveedores, y accesos directos a las dos secciones.
- CRUD completo de **productos**: crear, listar, buscar, editar y eliminar.
- CRUD completo de **proveedores**: crear, listar, buscar, editar y eliminar.
- Asociación de cada producto a un proveedor existente mediante un `Dropdown`.
- Listado de productos con el nombre del proveedor obtenido mediante
  `INNER JOIN`.
- Búsqueda por nombre con consultas `LIKE` y *debounce* para no saturar la base.
- Validación de formularios: campos obligatorios, precio mayor que cero, stock
  entero no negativo, teléfono y correo con formato básico.
- Protección de la integridad referencial: no se puede eliminar un proveedor
  que tenga productos asociados.
- Estados vacíos, mensajes de confirmación, errores comprensibles y diálogos de
  confirmación para acciones destructivas.
- Navegación inferior consistente y rutas con nombre para los formularios.

## Requisitos

- Flutter 3.47 o superior (Dart 3.13+).
- Para ejecutar en escritorio Linux/Windows se usa `sqflite_common_ffi`.
- En Android/iOS se usa `sqflite` de forma nativa.

## Ejecución

```bash
flutter pub get
flutter run
```

En Linux o Windows:

```bash
flutter run -d linux
# o
flutter run -d windows
```

> SQLite no está disponible en web con este enfoque. Ejecuta la app en Android,
> iOS, Linux, Windows o macOS.

### Pruebas

```bash
flutter test
flutter analyze
```

Las pruebas incluyen:

- Conversión de modelos (`fromMap` / `toMap`).
- CRUD real contra una base SQLite en memoria.
- Activación de `PRAGMA foreign_keys`.
- Bloqueo de eliminación de proveedores con productos.
- Rechazo de productos huérfanos por clave foránea.
- Persistencia de los datos al cerrar y reabrir una base de datos en disco.
- Cálculo de totales del dashboard.
- Flujo completo de interfaz: crear proveedor, crear producto, editar producto,
  intentar eliminar el proveedor con productos, eliminar producto y eliminar
  proveedor.

## Estructura del proyecto

```
lib/
├── main.dart                    # Arranque, tema, localización y rutas
├── models/
│   ├── producto.dart            # Modelo de producto
│   ├── proveedor.dart           # Modelo de proveedor
│   └── resumen_inventario.dart  # Totales del dashboard
├── routes/
│   └── app_routes.dart          # Rutas con nombre y paso de argumentos
├── screens/
│   ├── home_shell.dart          # Navegación inferior (Inicio/Productos/Proveedores)
│   ├── dashboard_screen.dart    # Pantalla principal
│   ├── productos_screen.dart    # Listado + búsqueda de productos
│   ├── producto_form_screen.dart# Registro y edición de productos
│   ├── proveedores_screen.dart  # Listado + búsqueda de proveedores
│   └── proveedor_form_screen.dart# Registro y edición de proveedores
├── services/
│   ├── database_service.dart    # Apertura, creación y PRAGMA foreign_keys
│   ├── producto_service.dart    # CRUD y consultas de productos
│   ├── proveedor_service.dart   # CRUD y consultas de proveedores
│   └── dashboard_service.dart   # Consultas agregadas
├── theme/
│   └── app_theme.dart           # Paleta, tipografía y estilos globales
├── utils/
│   ├── formato.dart             # Moneda e iniciales
│   └── mensajes.dart            # SnackBars y diálogos reutilizables
└── widgets/
    ├── campo_busqueda.dart
    ├── encabezado_formulario.dart
    ├── encabezado_seccion.dart
    ├── estado_vacio.dart
    ├── tarjeta_producto.dart
    ├── tarjeta_proveedor.dart
    └── tarjeta_resumen.dart
```

## Diseño de la base de datos

Base de datos: `inventario.db` (versión 1).

```sql
CREATE TABLE proveedores (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  telefono TEXT,
  correo TEXT
);

CREATE TABLE productos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  precio REAL NOT NULL CHECK (precio > 0),
  stock INTEGER NOT NULL CHECK (stock >= 0),
  proveedor_id INTEGER NOT NULL,
  FOREIGN KEY (proveedor_id)
    REFERENCES proveedores (id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);

CREATE INDEX idx_productos_proveedor ON productos (proveedor_id);
CREATE INDEX idx_productos_nombre ON productos (nombre);
CREATE INDEX idx_proveedores_nombre ON proveedores (nombre);
```

### Relación 1:N

Un proveedor puede suministrar varios productos; cada producto pertenece a un
único proveedor. La clave foránea es `productos.proveedor_id` y apunta a
`proveedores.id`.

- `PRAGMA foreign_keys = ON` se ejecuta en `onConfigure`, por lo que SQLite
  valida la relación en cada conexión.
- `ON DELETE RESTRICT` impide borrar un proveedor que tenga productos.
- Antes de eliminar, la app también consulta cuántos productos tiene el
  proveedor para informar al usuario con un mensaje claro.

### Consulta con INNER JOIN

```sql
SELECT
  p.id,
  p.nombre,
  p.precio,
  p.stock,
  p.proveedor_id,
  pr.nombre AS proveedor_nombre
FROM productos p
INNER JOIN proveedores pr ON pr.id = p.proveedor_id
ORDER BY p.nombre COLLATE NOCASE ASC;
```

El alias `proveedor_nombre` se lee en `Producto.fromMap` y se muestra en la
tarjeta del producto.

## Cómo demostrar el proyecto (guion para el video)

1. Abrir la app y mostrar el dashboard vacío.
2. Registrar un proveedor desde cero.
3. Ir a **Proveedores**: mostrar el listado, el buscador, el conteo de productos
   por proveedor y abrir el formulario de edición.
4. Ir a **Productos**: buscar un producto, mostrar precio, stock y proveedor.
5. Crear un producto nuevo y seleccionar el proveedor en el `Dropdown`.
6. Editar el producto y comprobar el cambio en la tarjeta.
7. Intentar eliminar un proveedor con productos: aparece el mensaje que impide
   la operación.
8. Eliminar un producto y luego su proveedor.
9. Cerrar la app, volver a abrirla y mostrar que los datos permanecen.
10. Ejecutar `flutter test` para mostrar las pruebas de integridad referencial.

## Explicación breve para la defensa

- **¿Dónde se guardan los datos?** En `inventario.db`, dentro del directorio de
  bases de datos de la app (`getDatabasesPath()`).
- **¿Cómo se crea la base?** `DatabaseService` usa `openDatabase` con
  `onCreate`; la primera vez ejecuta los `CREATE TABLE` y los índices.
- **¿Cómo se respeta la relación?** Con la clave foránea
  `productos.proveedor_id → proveedores.id`, `PRAGMA foreign_keys = ON` y
  `ON DELETE RESTRICT`.
- **¿Dónde está el INNER JOIN?** En `ProductoService.listar`, `obtenerPorId` y
  `listarStockBajo`; devuelve `proveedor_nombre` junto a cada producto.
- **¿Qué pasa si se elimina un proveedor con productos?** El servicio lo detecta
  dentro de una transacción, devuelve `conProductos` y la interfaz muestra un
  diálogo explicativo. Si se intentara directamente en SQLite, la clave foránea
  lo impediría.
- **¿Los datos persisten?** Sí, SQLite escribe en disco; la app no vuelve a crear
  las tablas al reabrir porque `onCreate` solo se ejecuta la primera vez.

## Evidencias de entrega

Para completar la entrega, captura:

1. Dashboard con datos.
2. Listado de productos con búsqueda activa.
3. Formulario de producto con el `Dropdown` de proveedor.
4. Listado de proveedores.
5. Formulario de proveedor con validación de correo.
6. Mensaje que impide eliminar un proveedor con productos.
7. Diálogo de confirmación de eliminación.
8. Estado vacío después de eliminar todos los registros.
9. Resultado de `flutter test` y `flutter analyze`.

Puedes generar capturas ejecutando la app en un emulador o dispositivo y usando
la herramienta de captura del sistema.
