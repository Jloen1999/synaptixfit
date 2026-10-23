import 'package:flutter/material.dart';

Widget buildGoogleButton(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
  required bool enabled,
}) => OutlinedButton.icon(
  onPressed: enabled ? onPressed : null,
  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
  label: Text(label),
);
