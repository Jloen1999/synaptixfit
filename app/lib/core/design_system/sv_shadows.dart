import 'package:flutter/material.dart';
import 'sv_colors.dart';

class SVShadows {
  // Capa 0 — casi plano, para tarjetas base
  static final List<BoxShadow> subtle = [
    BoxShadow(
      color: SVColors.onSurface.withValues(alpha: 0.03),
      offset: const Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  // Capa 1 — tarjetas estándar
  static final List<BoxShadow> ambientCard = [
    BoxShadow(
      color: SVColors.onSurface.withValues(alpha: 0.05),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: SVColors.onSurface.withValues(alpha: 0.02),
      offset: const Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  // Capa 2 — tarjetas elevadas, modales
  static final List<BoxShadow> ambientFloat = [
    BoxShadow(
      color: SVColors.onSurface.withValues(alpha: 0.08),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: SVColors.onSurface.withValues(alpha: 0.04),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: -1,
    ),
  ];

  // Capa 3 — elementos destacados, FABs, menús
  static final List<BoxShadow> elevated = [
    BoxShadow(
      color: SVColors.onSurface.withValues(alpha: 0.12),
      offset: const Offset(0, 12),
      blurRadius: 32,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: SVColors.onSurface.withValues(alpha: 0.06),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];

  // Sombra de color — para acentos (logros, XP)
  static List<BoxShadow> colored(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.2),
          offset: const Offset(0, 6),
          blurRadius: 16,
          spreadRadius: -2,
        ),
      ];

  // Sombra para glass
  static final List<BoxShadow> glass = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      offset: const Offset(0, -2),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];
}
