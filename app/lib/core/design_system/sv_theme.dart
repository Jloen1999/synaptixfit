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

      // AppBar — sin línea, superficie limpia
      appBarTheme: const AppBarTheme(
        backgroundColor: SVColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: SVColors.onSurface,
        ),
        iconTheme: IconThemeData(color: SVColors.onSurface),
      ),

      // Botones elevados — pill shape, sin elevación (sombras manuales)
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Inputs — filled con borde sutil
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SVColors.surfaceContainerLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: SVShapes.standard12,
          borderSide:
              BorderSide(color: SVColors.outlineVariant.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SVShapes.standard12,
          borderSide:
              BorderSide(color: SVColors.outlineVariant.withValues(alpha: 0.6)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: SVShapes.standard12,
          borderSide: BorderSide(color: SVColors.secondary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: SVShapes.standard12,
          borderSide: BorderSide(color: SVColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: SVShapes.standard12,
          borderSide: BorderSide(color: SVColors.error, width: 2),
        ),
        hintStyle:
            SVTypography.bodyMedium.copyWith(color: SVColors.onSurfaceMuted),
      ),

      // Cards — fondo blanco, sombra sutil, bordes redondeados
      cardTheme: const CardThemeData(
        color: SVColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: SVShapes.large16,
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // Chips — fondo suave, selección en verde
      chipTheme: ChipThemeData(
        backgroundColor: SVColors.surfaceContainerLow,
        selectedColor: SVColors.secondaryContainer,
        labelStyle: SVTypography.labelMedium.copyWith(
          color: SVColors.onSurfaceVariant,
        ),
        secondaryLabelStyle: SVTypography.labelMedium.copyWith(
          color: SVColors.onSecondaryContainer,
        ),
        shape: const RoundedRectangleBorder(borderRadius: SVShapes.pill),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),

      // SnackBar — fondo oscuro con acento
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SVColors.onSurface,
        contentTextStyle: SVTypography.bodyMedium.copyWith(
          color: SVColors.surfaceContainerLowest,
        ),
        shape: const RoundedRectangleBorder(borderRadius: SVShapes.standard12),
        behavior: SnackBarBehavior.floating,
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: SVColors.primary,
        unselectedLabelColor: SVColors.onSurfaceVariant,
        indicatorColor: SVColors.secondary,
        labelStyle:
            SVTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: SVTypography.labelLarge,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: SVColors.surfaceContainerHighest,
        thickness: 1,
        space: 0,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: SVColors.secondary,
        foregroundColor: SVColors.onSecondary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
