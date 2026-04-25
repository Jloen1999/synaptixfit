import 'package:flutter/material.dart';

class SVColors {
  // Core Tones
  static const Color primary = Color(0xFF002546);
  static const Color primaryContainer = Color(0xFF0D3B66);
  static const Color secondary = Color(0xFF006E2D);
  static const Color secondaryContainer = Color(0xFF72FE8F);
  static const Color tertiary = Color(0xFF002A24);
  
  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF7FAFC);
  static const Color surface = Color(0xFFF7FAFC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F4F6);
  static const Color surfaceContainer = Color(0xFFEEF0EE); // Approx from #ebeef0
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);

  // Text / On Colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF007430);
  static const Color onBackground = Color(0xFF181C1E);
  static const Color onSurface = Color(0xFF181C1E);
  static const Color onSurfaceVariant = Color(0xFF42474F);

  // Aliases de conveniencia (compatibilidad con pantallas de ejercicios)
  /// Equivalente a [surfaceContainerHighest]. Fondo de tarjetas/contenedores.
  static const Color surfaceVariant = surfaceContainerHighest;
  /// Equivalente a [onSurfaceVariant]. Texto e íconos secundarios.
  static const Color textSecondary = onSurfaceVariant;

  // States
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFF737780);
  static const Color outlineVariant = Color(0xFFC3C6D0);

  // Theme Extension Helpers
  static ColorScheme get colorScheme =>
      ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light)
          .copyWith(
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
