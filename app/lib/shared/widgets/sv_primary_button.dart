import 'package:flutter/material.dart';

import '../../core/design_system/sv_colors.dart';
import '../../core/design_system/sv_shapes.dart';

class SVPrimaryButton extends StatelessWidget {
  const SVPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(borderRadius: SVShapes.pill),
        backgroundColor: SVColors.primary,
        foregroundColor: SVColors.onPrimary,
      ),
    );
  }
}
