import 'package:flutter/material.dart';

class SVColors {
  // Core Tones
  static const Color primary = Color(0xFF002546);
  static const Color primaryContainer = Color(0xFF0D3B66);
  static const Color secondary = Color(0xFF006E2D);
  static const Color secondaryContainer = Color(0xFF72FE8F);
  static const Color tertiary = Color(0xFF002A24);

  // Accent — logros, XP, gamificación
  static const Color accent = Color(0xFFE8A838);
  static const Color accentContainer = Color(0xFFFFF3D6);
  static const Color onAccent = Color(0xFF3D2600);
  static const Color onAccentContainer = Color(0xFF5C3A00);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFF5F7FA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEEF1F5);
  static const Color surfaceContainer = Color(0xFFE8EBEF);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E7);
  static const Color surfaceDim = Color(0xFFD8DBDF);

  // Text / On Colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF007430);
  static const Color onBackground = Color(0xFF181C1E);
  static const Color onSurface = Color(0xFF181C1E);
  static const Color onSurfaceVariant = Color(0xFF42474F);
  static const Color onSurfaceMuted = Color(0xFF6B7280);

  // Aliases de conveniencia
  static const Color surfaceVariant = surfaceContainerHighest;
  static const Color textSecondary = onSurfaceVariant;

  // States
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFF737780);
  static const Color outlineVariant = Color(0xFFC3C6D0);

  // KPI gradient stops
  static const Color kpiCalorias = Color(0xFFFF6B35);
  static const Color kpiSesiones = Color(0xFF2196F3);
  static const Color kpiEstudio = Color(0xFF7C4DFF);
  static const Color kpiRacha = Color(0xFFE8A838);

  static ColorScheme get colorScheme => ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        surface: surface,
        error: error,
        onError: onError,
        onSurface: onSurface,
        outline: outline,
        outlineVariant: outlineVariant,
      );
}
