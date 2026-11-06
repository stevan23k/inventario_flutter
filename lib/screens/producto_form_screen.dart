import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/producto.dart';
import '../models/proveedor.dart';
import '../routes/app_routes.dart';
import '../services/producto_service.dart';
import '../services/proveedor_service.dart';
import '../theme/app_theme.dart';
import '../utils/mensajes.dart';
import '../widgets/encabezado_formulario.dart';
import '../widgets/encabezado_seccion.dart';

class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({super.key, this.producto});

  final Producto? producto;

  bool get esEdicion => producto != null;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  final ProductoService _productoService = ProductoService();
  final ProveedorService _proveedorService = ProveedorService();

  List<Proveedor> _proveedores = const [];
  int? _proveedorSeleccionado;
  bool _cargandoProveedores = true;
  String? _errorProveedores;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final Producto? producto = widget.producto;
    if (producto != null) {
      _nombreController.text = producto.nombre;
      _precioController.text = _formatearPrecio(producto.precio);
      _stockController.text = '${producto.stock}';
      _proveedorSeleccionado = producto.proveedorId;
    }
    _cargarProveedores(mostrarCarga: false);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  String _formatearPrecio(double valor) {
    if (valor == valor.roundToDouble()) return valor.toStringAsFixed(0);
    return valor.toStringAsFixed(2);
  }

  Future<void> _cargarProveedores({
    int? seleccionar,
    bool mostrarCarga = true,
  }) async {
    if (mostrarCarga && mounted) {
      setState(() {
        _cargandoProveedores = true;
        _errorProveedores = null;
      });
    }

    try {
      final List<Proveedor> lista = await _proveedorService.listar();
      if (!mounted) return;
      setState(() {
        _proveedores = lista;
        _cargandoProveedores = false;
        _errorProveedores = null;
        final int? objetivo = seleccionar ?? _proveedorSeleccionado;
        _proveedorSeleccionado = lista.any((Proveedor p) => p.id == objetivo)
            ? objetivo
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargandoProveedores = false;
        _errorProveedores = 'No se pudieron cargar los proveedores.';
      });
    }
  }

  Future<void> _abrirNuevoProveedor() async {
    final Proveedor? creado = await Navigator.of(context)
        .pushNamed<Proveedor?>(AppRoutes.proveedorFormulario);
    if (creado == null || !mounted) return;

    await _cargarProveedores(seleccionar: creado.id);
    if (!mounted) return;
    mostrarMensaje(
      context,
      'Proveedor "${creado.nombre}" creado y seleccionado.',
    );
  }

  String? _validarNombre(String? value) {
    final String texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa el nombre del producto.';
    if (texto.length < 2) return 'El nombre debe tener al menos 2 caracteres.';
    return null;
  }

  String? _validarPrecio(String? value) {
    final String texto = (value ?? '').trim().replaceAll(',', '.');
    if (texto.isEmpty) return 'Ingresa el precio.';
    final double? precio = double.tryParse(texto);
    if (precio == null) return 'Ingresa un valor numérico válido.';
    if (precio <= 0) return 'El precio debe ser mayor que 0.';
    return null;
  }

  String? _validarStock(String? value) {
    final String texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa el stock.';
    final int? stock = int.tryParse(texto);
    if (stock == null) return 'Ingresa una cantidad válida.';
    if (stock < 0) return 'El stock no puede ser negativo.';
    return null;
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    final bool formularioValido = _formKey.currentState?.validate() ?? false;
    if (!formularioValido) return;

    if (_proveedorSeleccionado == null) {
      mostrarMensaje(
        context,
        'Selecciona un proveedor para el producto.',
        esError: true,
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final double precio = double.parse(
        _precioController.text.trim().replaceAll(',', '.'),
      );
      final int stock = int.parse(_stockController.text.trim());

      Producto producto = Producto(
        id: widget.producto?.id,
        nombre: _nombreController.text.trim(),
        precio: precio,
        stock: stock,
        proveedorId: _proveedorSeleccionado!,
        proveedorNombre: widget.producto?.proveedorNombre,
      );

      if (widget.esEdicion) {
        await _productoService.actualizar(producto);
      } else {
        final int id = await _productoService.crear(producto);
        producto = producto.copyWith(id: id);
      }

      if (!mounted) return;
      Navigator.of(context).pop(producto);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarMensaje(
        context,
        'No se pudo guardar el producto. Intenta de nuevo.',
        esError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              EncabezadoFormulario(
                icono: widget.esEdicion
                    ? Icons.edit_note_rounded
                    : Icons.add_box_outlined,
                titulo: widget.esEdicion
                    ? 'Actualiza los datos del producto'
                    : 'Registra un nuevo producto',
                mensaje: widget.esEdicion
                    ? 'Modifica la información y guarda los cambios para actualizar el inventario.'
                    : 'Completa la información y asígnalo a un proveedor existente.',
              ),
              const SizedBox(height: 22),
              const EncabezadoSeccion(titulo: 'Información del producto'),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nombreController,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto *',
                  hintText: 'Ej. Café molido 500 g',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  counterText: '',
                ),
                validator: _validarNombre,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Widget precio = TextFormField(
                    controller: _precioController,
                    enabled: !_guardando,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Precio *',
                      hintText: '0,00',
                      prefixText: '\$ ',
                    ),
                    validator: _validarPrecio,
                  );

                  final Widget stock = TextFormField(
                    controller: _stockController,
                    enabled: !_guardando,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Stock *',
                      hintText: '0',
                    ),
                    validator: _validarStock,
                  );

                  if (constraints.maxWidth < 300) {
                    return Column(
                      children: [precio, const SizedBox(height: 16), stock],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: precio),
                      const SizedBox(width: 12),
                      Expanded(child: stock),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              const EncabezadoSeccion(titulo: 'Proveedor'),
              const SizedBox(height: 14),
              _construirSelectorProveedor(),
              const SizedBox(height: 8),
              const Text(
                '* Campos obligatorios',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 20),
                  label: Text(
                    _guardando
                        ? 'Guardando...'
                        : widget.esEdicion
                        ? 'Guardar cambios'
                        : 'Guardar producto',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _guardando
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirSelectorProveedor() {
    if (_cargandoProveedores) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Cargando proveedores...',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorProveedores != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorProveedores!,
                style: const TextStyle(fontSize: 12.5, color: AppColors.danger),
              ),
            ),
            TextButton(
              onPressed: _cargarProveedores,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_proveedores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No hay proveedores registrados',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Registra un proveedor antes de guardar el producto.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _guardando ? null : _abrirNuevoProveedor,
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: const Text('Crear proveedor'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: AppColors.surface,
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _proveedorSeleccionado,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Proveedor *',
        hintText: 'Selecciona un proveedor',
        prefixIcon: Icon(Icons.storefront_outlined),
      ),
      items: _proveedores
          .map(
            (Proveedor proveedor) => DropdownMenuItem<int>(
              value: proveedor.id,
              child: Text(
                proveedor.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _guardando
          ? null
          : (int? value) {
              setState(() => _proveedorSeleccionado = value);
            },
      validator: (int? value) {
        if (value == null) return 'Selecciona un proveedor.';
        return null;
      },
    );
  }
}
