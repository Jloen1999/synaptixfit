import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SVTypography {
  // Display & Headlines — Manrope (geométrico, moderno, carácter)
  static TextStyle get displayLarge => GoogleFonts.manrope(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.25,
      );

  static TextStyle get displayMedium => GoogleFonts.manrope(
        fontSize: 45,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get displaySmall => GoogleFonts.manrope(
        fontSize: 36,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get headlineLarge => GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get headlineMedium => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get headlineSmall => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleLarge => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleMedium => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleSmall => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  // Body & Labels — DM Sans (geométrico cálido, mejor legibilidad que Inter)
  static TextStyle get bodyLarge => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
      );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.05,
      );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get labelLarge => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );

  static TextStyle get labelSmall => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      );

  // Estilo para números grandes (KPIs)
  static TextStyle get metricValue => GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle get metricUnit => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      );

  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
