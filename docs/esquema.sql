-- Esquema de la base de datos local de StockFlow.
-- Este archivo documenta el SQL que ejecuta DatabaseService en onCreate.

PRAGMA foreign_keys = ON;

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
