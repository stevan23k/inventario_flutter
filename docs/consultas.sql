-- Consultas principales de la aplicación.

-- 1. Listado de productos con el nombre de su proveedor (INNER JOIN).
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

-- 2. Búsqueda de productos por nombre.
SELECT
  p.id,
  p.nombre,
  p.precio,
  p.stock,
  p.proveedor_id,
  pr.nombre AS proveedor_nombre
FROM productos p
INNER JOIN proveedores pr ON pr.id = p.proveedor_id
WHERE p.nombre LIKE '%café%'
ORDER BY p.nombre COLLATE NOCASE ASC;

-- 3. Proveedores con la cantidad de productos asociados (LEFT JOIN).
SELECT
  pr.id,
  pr.nombre,
  pr.telefono,
  pr.correo,
  COUNT(p.id) AS total_productos
FROM proveedores pr
LEFT JOIN productos p ON p.proveedor_id = pr.id
GROUP BY pr.id, pr.nombre, pr.telefono, pr.correo
ORDER BY pr.nombre COLLATE NOCASE ASC;

-- 4. Verificar si un proveedor puede eliminarse.
SELECT COUNT(*)
FROM productos
WHERE proveedor_id = 1;

-- 5. Resumen del dashboard.
SELECT
  (SELECT COUNT(*) FROM productos) AS total_productos,
  (SELECT COUNT(*) FROM proveedores) AS total_proveedores,
  (SELECT COALESCE(SUM(stock), 0) FROM productos) AS unidades_en_stock,
  (SELECT COALESCE(SUM(precio * stock), 0) FROM productos) AS valor_inventario,
  (SELECT COUNT(*) FROM productos WHERE stock <= 5) AS productos_stock_bajo;

-- 6. Productos con stock bajo.
SELECT
  p.id,
  p.nombre,
  p.precio,
  p.stock,
  p.proveedor_id,
  pr.nombre AS proveedor_nombre
FROM productos p
INNER JOIN proveedores pr ON pr.id = p.proveedor_id
WHERE p.stock <= 5
ORDER BY p.stock ASC, p.nombre COLLATE NOCASE ASC;
