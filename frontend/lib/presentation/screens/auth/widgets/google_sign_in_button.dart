import 'package:flutter/material.dart';

import 'google_sign_in_button_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_button_web.dart'
    as platform;

/// Botón de Google. En web pinta el botón oficial de Google (obligatorio en esa
/// plataforma) y avisa con [onPressed] al montarse para que el bloc espere el
/// resultado; en móvil es un botón normal que lanza el flujo nativo.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => platform.buildGoogleButton(
    context,
    label: label,
    onPressed: onPressed,
    enabled: enabled,
  );
}
