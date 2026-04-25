import 'package:flutter/material.dart';
import 'sv_colors.dart';
import 'sv_typography.dart';
import 'sv_shapes.dart';

class SVTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: SVColors.colorScheme,
      textTheme: SVTypography.textTheme,
      scaffoldBackgroundColor: SVColors.background,
      
      // Configuración de AppBar (sin línea)
      appBarTheme: AppBarTheme(
        backgroundColor: SVColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: SVTypography.titleLarge.copyWith(color: SVColors.onSurface),
        iconTheme: const IconThemeData(color: SVColors.onSurface),
      ),

      // Configuración de Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SVColors.primary,
          foregroundColor: SVColors.onPrimary,
          shape: const RoundedRectangleBorder(borderRadius: SVShapes.pill),
          elevation: 0,
          textStyle: SVTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SVColors.primary,
          side: const BorderSide(color: SVColors.outlineVariant),
          shape: const RoundedRectangleBorder(borderRadius: SVShapes.pill),
          textStyle: SVTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SVColors.primary,
          textStyle: SVTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SVColors.surfaceContainerLowest,
        border: const OutlineInputBorder(
          borderRadius: SVShapes.standard,
          borderSide: BorderSide(color: SVColors.outlineVariant, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: SVShapes.standard,
          borderSide: BorderSide(color: SVColors.outlineVariant, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: SVShapes.standard,
          borderSide: BorderSide(color: SVColors.secondary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: SVShapes.standard,
          borderSide: BorderSide(color: SVColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: SVTypography.bodyMedium.copyWith(color: SVColors.outline),
      ),

      // Cards
      cardTheme: const CardThemeData(
        color: SVColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: SVShapes.large,
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: SVColors.surfaceContainerLow,
        selectedColor: SVColors.secondaryContainer,
        labelStyle: SVTypography.labelMedium.copyWith(color: SVColors.onSurfaceVariant),
        secondaryLabelStyle: SVTypography.labelMedium.copyWith(color: SVColors.onSecondaryContainer),
        shape: const RoundedRectangleBorder(borderRadius: SVShapes.pill),
        side: BorderSide.none,
      ),
    );
  }
}
