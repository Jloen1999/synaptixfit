import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_icons.dart';

/// Campo de texto con etiqueta visible, icono, ayuda y modo contraseña (con
/// botón de mostrar/ocultar anunciado al lector de pantalla).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.validator,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.autofillHints,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onSubmitted,
    this.onChanged,
    this.onTap,
    this.hint,
    this.helper,
    this.suffixText,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.errorText,
    this.autocorrect = true,
  });

  final String label;
  final String? hint;

  /// Texto de ayuda bajo el campo (formato esperado, límites…).
  final String? helper;
  final String? suffixText;
  final TextEditingController? controller;
  final String? initialValue;
  final String? Function(String?)? validator;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  /// Error mostrado junto al campo sin pasar por un `Form` (p. ej. el que
  /// llega del bloc).
  final String? errorText;

  /// `false` en direcciones y códigos: sin autocorrector ni sugerencias.
  final bool autocorrect;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return TextFormField(
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _hidden,
      autofillHints: widget.autofillHints,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      minLines: widget.obscure ? null : widget.minLines,
      maxLength: widget.maxLength,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      focusNode: widget.focusNode,
      inputFormatters: widget.inputFormatters,
      textCapitalization: widget.textCapitalization,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.autocorrect,
      decoration: InputDecoration(
        errorText: widget.errorText,
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helper,
        suffixText: widget.suffixText,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        suffixIcon: widget.obscure
            ? IconButton(
                tooltip: _hidden
                    ? l10n.fieldShowPassword
                    : l10n.fieldHidePassword,
                icon: Icon(
                  _hidden ? AppIcons.showPassword : AppIcons.hidePassword,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
  }
}
