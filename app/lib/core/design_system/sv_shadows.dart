import 'package:flutter/material.dart';
import 'sv_colors.dart';

class SVShadows {
  // Ambient Shadows (difusas, nunca negro puro)
  static final List<BoxShadow> ambientFloat = [
    BoxShadow(
      color: SVColors.onSurface.withValues(alpha: 0.08),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> ambientCard = [
    BoxShadow(
      color: SVColors.onSurface.withValues(alpha: 0.04),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
}
