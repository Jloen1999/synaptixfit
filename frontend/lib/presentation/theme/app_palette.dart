import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// Colores semánticos de SynaptixFit que Material no cubre (logro, estados y
/// métricas). Se leen con `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.success,
    required this.warning,
    required this.calories,
    required this.sessions,
    required this.study,
    required this.streak,
  });

  static const light = AppPalette(
    accent: TokensLightColors.accent,
    onAccent: TokensLightColors.onAccent,
    accentContainer: TokensLightColors.accentContainer,
    onAccentContainer: TokensLightColors.onAccentContainer,
    success: TokensLightColors.success,
    warning: TokensLightColors.warning,
    calories: TokensLightColors.calories,
    sessions: TokensLightColors.sessions,
    study: TokensLightColors.study,
    streak: TokensLightColors.streak,
  );

  static const dark = AppPalette(
    accent: TokensDarkColors.accent,
    onAccent: TokensDarkColors.onAccent,
    accentContainer: TokensDarkColors.accentContainer,
    onAccentContainer: TokensDarkColors.onAccentContainer,
    success: TokensDarkColors.success,
    warning: TokensDarkColors.warning,
    calories: TokensDarkColors.calories,
    sessions: TokensDarkColors.sessions,
    study: TokensDarkColors.study,
    streak: TokensDarkColors.streak,
  );

  /// Logro, XP, rachas e insignias.
  final Color accent;
  final Color onAccent;
  final Color accentContainer;

  /// Texto e iconos sobre [accentContainer] (el ámbar puro no llega a AA como texto).
  final Color onAccentContainer;
  final Color success;
  final Color warning;

  /// Métricas.
  final Color calories;
  final Color sessions;
  final Color study;
  final Color streak;

  @override
  AppPalette copyWith({
    Color? accent,
    Color? onAccent,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? success,
    Color? warning,
    Color? calories,
    Color? sessions,
    Color? study,
    Color? streak,
  }) => AppPalette(
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentContainer: accentContainer ?? this.accentContainer,
    onAccentContainer: onAccentContainer ?? this.onAccentContainer,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    calories: calories ?? this.calories,
    sessions: sessions ?? this.sessions,
    study: study ?? this.study,
    streak: streak ?? this.streak,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      onAccentContainer: Color.lerp(
        onAccentContainer,
        other.onAccentContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      calories: Color.lerp(calories, other.calories, t)!,
      sessions: Color.lerp(sessions, other.sessions, t)!,
      study: Color.lerp(study, other.study, t)!,
      streak: Color.lerp(streak, other.streak, t)!,
    );
  }
}
