import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/proveedor.dart';
import '../services/proveedor_service.dart';
import '../theme/app_theme.dart';
import '../utils/mensajes.dart';
import '../widgets/encabezado_formulario.dart';
import '../widgets/encabezado_seccion.dart';

class ProveedorFormScreen extends StatefulWidget {
  const ProveedorFormScreen({super.key, this.proveedor});

  final Proveedor? proveedor;

  bool get esEdicion => proveedor != null;

  @override
  State<ProveedorFormScreen> createState() => _ProveedorFormScreenState();
}

class _ProveedorFormScreenState extends State<ProveedorFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();

  final ProveedorService _proveedorService = ProveedorService();

  bool _guardando = false;

  static final RegExp _correoValido = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  @override
  void initState() {
    super.initState();
    final Proveedor? proveedor = widget.proveedor;
    if (proveedor != null) {
      _nombreController.text = proveedor.nombre;
      _telefonoController.text = proveedor.telefono ?? '';
      _correoController.text = proveedor.correo ?? '';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  String? _validarNombre(String? value) {
    final String texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa el nombre o razón social.';
    if (texto.length < 2) return 'El nombre debe tener al menos 2 caracteres.';
    return null;
  }

  String? _validarTelefono(String? value) {
    final String texto = (value ?? '').trim();
    if (texto.isEmpty) return null;
    final String digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.length < 7) {
      return 'Ingresa un teléfono válido (mínimo 7 dígitos).';
    }
    return null;
  }

  String? _validarCorreo(String? value) {
    final String texto = (value ?? '').trim();
    if (texto.isEmpty) return null;
    if (!_correoValido.hasMatch(texto)) {
      return 'Ingresa un correo válido. Ej: nombre@dominio.com';
    }
    return null;
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    final bool formularioValido = _formKey.currentState?.validate() ?? false;
    if (!formularioValido) return;

    setState(() => _guardando = true);

    try {
      final String telefono = _telefonoController.text.trim();
      final String correo = _correoController.text.trim();

      Proveedor proveedor = Proveedor(
        id: widget.proveedor?.id,
        nombre: _nombreController.text.trim(),
        telefono: telefono.isEmpty ? null : telefono,
        correo: correo.isEmpty ? null : correo,
        totalProductos: widget.proveedor?.totalProductos ?? 0,
      );

      if (widget.esEdicion) {
        await _proveedorService.actualizar(proveedor);
      } else {
        final int id = await _proveedorService.crear(proveedor);
        proveedor = proveedor.copyWith(id: id);
      }

      if (!mounted) return;
      Navigator.of(context).pop(proveedor);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarMensaje(
        context,
        'No se pudo guardar el proveedor. Intenta de nuevo.',
        esError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int productosAsociados = widget.proveedor?.totalProductos ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar proveedor' : 'Nuevo proveedor'),
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
                    : Icons.add_business_outlined,
                titulo: widget.esEdicion
                    ? 'Actualiza los datos del proveedor'
                    : 'Registra un nuevo proveedor',
                mensaje: widget.esEdicion
                    ? 'Los cambios se reflejarán en todos los productos asociados.'
                    : 'Después podrás asociarle productos desde el formulario de producto.',
              ),
              if (widget.esEdicion && productosAsociados > 0) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 19,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este proveedor tiene $productosAsociados '
                          '${productosAsociados == 1 ? 'producto asociado' : 'productos asociados'}. '
                          'Para eliminarlo deberás reasignar o borrar sus productos.',
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const EncabezadoSeccion(titulo: 'Datos del proveedor'),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nombreController,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nombre o razón social *',
                  hintText: 'Ej. Distribuidora El Progreso',
                  prefixIcon: Icon(Icons.storefront_outlined),
                  counterText: '',
                ),
                validator: _validarNombre,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                enabled: !_guardando,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  hintText: 'Ej. +57 300 123 4567',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: _validarTelefono,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoController,
                enabled: !_guardando,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'Ej. ventas@proveedor.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: _validarCorreo,
              ),
              const SizedBox(height: 8),
              const Text(
                '* Campo obligatorio. El teléfono y el correo son opcionales.',
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
                        : 'Guardar proveedor',
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
}
