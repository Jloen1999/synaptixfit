import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget buildGoogleButton(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
  required bool enabled,
}) => _WebGoogleButton(onReady: onPressed);

class _WebGoogleButton extends StatefulWidget {
  const _WebGoogleButton({required this.onReady});

  final VoidCallback onReady;

  @override
  State<_WebGoogleButton> createState() => _WebGoogleButtonState();
}

class _WebGoogleButtonState extends State<_WebGoogleButton> {
  @override
  void initState() {
    super.initState();
    // En web el flujo lo inicia el botón oficial: el bloc queda esperando su evento.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onReady());
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 44, child: Center(child: web.renderButton()));
}
