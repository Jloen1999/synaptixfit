import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import 'app_focus_outline.dart';
import 'app_inline_message.dart';

/// Casilla obligatoria de un formulario («He leído y acepto…», «Doy mi
/// permiso…»). Es un campo: sin marcarla, el botón del formulario explica junto
/// a ella por qué no sigue, en vez de quedarse desactivado sin decir nada.
class AppConsentCheckbox extends StatelessWidget {
  const AppConsentCheckbox({
    super.key,
    required this.label,
    required this.requiredMessage,
    this.enabled = true,
    this.autofocus = false,
  });

  final String label;

  /// Lo que se dice si se intenta seguir sin marcarla.
  final String requiredMessage;
  final bool enabled;

  /// Pon el foco aquí al abrir: es lo primero que hay que hacer en la pantalla.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: false,
      validator: (value) => value ?? false ? null : requiredMessage,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFocusOutline(
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              autofocus: autofocus,
              value: field.value ?? false,
              onChanged: enabled ? (v) => field.didChange(v ?? false) : null,
              title: Text(label, style: context.textStyles.bodyMedium),
            ),
          ),
          if (field.errorText case final error?)
            AppInlineMessage(message: error),
        ],
      ),
    );
  }
}
