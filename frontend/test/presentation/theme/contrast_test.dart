import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/theme/tokens.g.dart';
import 'package:synaptixfit/presentation/widgets/app_pill.dart';

/// Comprueba que las parejas de color del sistema de diseño cumplen WCAG 2.2 AA:
/// 4,5:1 para texto y 3:1 para iconos, bordes de campos y gráficos.
void main() {
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final (hi, lo) = la > lb ? (la, lb) : (lb, la);
    return (hi + 0.05) / (lo + 0.05);
  }

  void expectRatio(String name, Color fg, Color bg, double min) {
    expect(
      contrast(fg, bg),
      greaterThanOrEqualTo(min),
      reason: '$name: ${contrast(fg, bg).toStringAsFixed(2)} < $min',
    );
  }

  for (final (mode, c) in [
    ('claro', _Colors.light),
    ('oscuro', _Colors.dark),
  ]) {
    group('tema $mode', () {
      test('texto', () {
        for (final bg in [c.surface, c.background, c.surfaceContainerHigh]) {
          expectRatio('onSurface', c.onSurface, bg, 4.5);
          expectRatio('onSurfaceVariant', c.onSurfaceVariant, bg, 4.5);
          expectRatio('primary', c.primary, bg, 4.5);
          expectRatio('error', c.error, bg, 4.5);
        }
        // Campos de texto: rellenos con surfaceContainerLow.
        expectRatio('onSurface/campo', c.onSurface, c.surfaceContainerLow, 4.5);
        expectRatio(
          'onSurfaceVariant/campo',
          c.onSurfaceVariant,
          c.surfaceContainerLow,
          4.5,
        );
        // Barra de navegación: destino activo en primary sobre el indicador
        // sutil (primary al 12 %) e inactivos en onSurfaceVariant.
        expectRatio(
          'primary/navIndicator',
          c.primary,
          Color.alphaBlend(c.primary.withValues(alpha: 0.12), c.navigationBar),
          4.5,
        );
        expectRatio(
          'onSurfaceVariant/navBar',
          c.onSurfaceVariant,
          c.navigationBar,
          4.5,
        );
        expectRatio('onPrimary', c.onPrimary, c.primary, 4.5);
        expectRatio('onSecondary', c.onSecondary, c.secondary, 4.5);
        expectRatio('onTertiary', c.onTertiary, c.tertiary, 4.5);
        expectRatio('onError', c.onError, c.error, 4.5);
        expectRatio(
          'onPrimaryC',
          c.onPrimaryContainer,
          c.primaryContainer,
          4.5,
        );
        expectRatio(
          'onSecondaryC',
          c.onSecondaryContainer,
          c.secondaryContainer,
          4.5,
        );
        expectRatio(
          'onTertiaryC',
          c.onTertiaryContainer,
          c.tertiaryContainer,
          4.5,
        );
        expectRatio('onAccentC', c.onAccentContainer, c.accentContainer, 4.5);
        expectRatio('onErrorC', c.onErrorContainer, c.errorContainer, 4.5);
        for (final color in [c.success, c.warning, c.secondary, c.tertiary]) {
          expectRatio('estado $color', color, c.surface, 4.5);
        }
        // El ámbar también se usa como texto (nivel, racha) y como fondo de
        // botones con texto encima.
        expectRatio('accent', c.accent, c.surface, 4.5);
        expectRatio('accent/accentC', c.accent, c.accentContainer, 4.5);
        expectRatio('onAccent', c.onAccent, c.accent, 4.5);
      });

      // Patrón «pastilla» ([AppPill]): texto de un color sobre ese mismo color
      // al 12 % fundido con `surface`. Esta lista debe contener todos los
      // colores que se pasan como texto a una pastilla; `outline` no está a
      // propósito (solo bordes e iconos: no llega a 4,5:1).
      test('pastillas tintadas', () {
        for (final color in [
          c.primary,
          c.secondary,
          c.tertiary,
          c.accent,
          c.error,
          c.success,
          c.warning,
          c.calories,
          c.sessions,
          c.study,
          c.streak,
          c.onSurfaceVariant,
        ]) {
          final tint = Color.alphaBlend(
            color.withValues(alpha: AppPill.tintAlpha),
            c.surface,
          );
          expectRatio('pastilla $color', color, tint, 4.5);
        }
        // Pastilla dentro de la tarjeta destacada de Rutinas.
        expectRatio(
          'pastilla onSecondaryC',
          c.onSecondaryContainer,
          Color.alphaBlend(
            c.onSecondaryContainer.withValues(alpha: AppPill.tintAlpha),
            c.surface,
          ),
          4.5,
        );
      });

      // Tarjeta de rutina con foto de fondo ([AppCoverCard]): la foto va a
      // dos tonos entre la superficie y una mezcla de primary
      // (coverTintLight / coverTintDark), así que el peor fondo posible bajo
      // el texto es esa mezcla (también es el extremo del degradado sin
      // foto). Las pastillas van sobre una base opaca de superficie
      // (AppCoverPill): las cubre «pastillas tintadas».
      test('tarjeta con foto de fondo', () {
        final bg = Color.lerp(
          c.surface,
          c.primary,
          mode == 'oscuro'
              ? TokensOpacity.coverTintDark
              : TokensOpacity.coverTintLight,
        )!;
        expectRatio('portada onSurface', c.onSurface, bg, 4.5);
        expectRatio('portada onSurfaceVariant', c.onSurfaceVariant, bg, 4.5);
        expectRatio('portada primary', c.primary, bg, 4.5);
      });

      // Sesión en vivo y repaso: el tinte va opaco sobre la superficie, así
      // que su contraste no depende de lo que haya detrás (la cabecera es
      // surfaceContainerLow; la nota elegida, primaryContainer).
      test('sesión en vivo y repaso', () {
        Color tint(Color color) => Color.alphaBlend(
          color.withValues(alpha: AppPill.tintAlpha),
          c.surface,
        );
        for (final behind in [c.surfaceContainerLow, c.primaryContainer]) {
          // Lo que hay detrás no cuenta: el tinte ya es opaco.
          final pill = Color.alphaBlend(tint(c.warning), behind);
          expectRatio('píldora en pausa sobre $behind', c.warning, pill, 4.5);
        }
        expectRatio(
          'píldora del tiempo real',
          c.onAccentContainer,
          c.accentContainer,
          4.5,
        );
        for (final color in [c.success, c.warning, c.error]) {
          expectRatio('cifra de la nota $color', color, tint(color), 4.5);
        }
        // Serie en pausa: texto de la fila y su estado «En pausa».
        expectRatio('fila en pausa', c.onSurface, tint(c.warning), 4.5);
        expectRatio('estado en pausa', c.warning, tint(c.warning), 4.5);
        // Pasos numerados (AppStepBadge): activo y bloqueado; la marca de
        // hecho es un icono (3:1).
        expectRatio(
          'paso activo',
          c.onPrimaryContainer,
          c.primaryContainer,
          4.5,
        );
        expectRatio(
          'paso bloqueado',
          c.onSurfaceVariant,
          c.surfaceContainerHigh,
          4.5,
        );
        expectRatio('paso hecho', c.surface, c.success, 3);
        // Nota elegida: borde primary sobre la tarjeta (1.4.11).
        expectRatio('borde nota elegida', c.primary, c.surface, 3);
      });

      test('gráficos e iconos', () {
        for (final color in [
          c.accent,
          c.calories,
          c.sessions,
          c.study,
          c.streak,
          c.outline,
        ]) {
          expectRatio('gráfico $color', color, c.surface, 3);
        }
        // Borde de los campos (WCAG 1.4.11) contra su relleno y el lienzo.
        expectRatio('outline/campo', c.outline, c.surfaceContainerLow, 3);
        expectRatio('outline/fondo', c.outline, c.background, 3);
        // Anillo de foco de la navegación (AppNavFocusRing) contra la barra y
        // contra el indicador del destino activo (WCAG 2.4.7 y 1.4.11).
        expectRatio('focusRing/navBar', c.onSurface, c.navigationBar, 3);
        expectRatio(
          'focusRing/navIndicator',
          c.onSurface,
          Color.alphaBlend(c.primary.withValues(alpha: 0.12), c.navigationBar),
          3,
        );
        // Chip «Filtros» con filtros activos: etiqueta sobre primaryContainer.
        expectRatio('onSurface/primaryC', c.onSurface, c.primaryContainer, 4.5);
      });
    });
  }
}

/// Los colores de un modo como instancia, para recorrer ambos temas igual.
class _Colors {
  const _Colors({
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.surface,
    required this.background,
    required this.surfaceContainerHigh,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
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
    required this.outline,
    required this.surfaceContainerLow,
    required this.navigationBar,
  });

  static const light = _Colors(
    onSurface: TokensLightColors.onSurface,
    onSurfaceVariant: TokensLightColors.onSurfaceVariant,
    surface: TokensLightColors.surface,
    background: TokensLightColors.background,
    surfaceContainerHigh: TokensLightColors.surfaceContainerHigh,
    primary: TokensLightColors.primary,
    onPrimary: TokensLightColors.onPrimary,
    primaryContainer: TokensLightColors.primaryContainer,
    onPrimaryContainer: TokensLightColors.onPrimaryContainer,
    secondary: TokensLightColors.secondary,
    onSecondary: TokensLightColors.onSecondary,
    secondaryContainer: TokensLightColors.secondaryContainer,
    onSecondaryContainer: TokensLightColors.onSecondaryContainer,
    tertiary: TokensLightColors.tertiary,
    onTertiary: TokensLightColors.onTertiary,
    tertiaryContainer: TokensLightColors.tertiaryContainer,
    onTertiaryContainer: TokensLightColors.onTertiaryContainer,
    error: TokensLightColors.error,
    onError: TokensLightColors.onError,
    errorContainer: TokensLightColors.errorContainer,
    onErrorContainer: TokensLightColors.onErrorContainer,
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
    outline: TokensLightColors.outline,
    surfaceContainerLow: TokensLightColors.surfaceContainerLow,
    navigationBar: TokensLightColors.navigationBar,
  );

  static const dark = _Colors(
    onSurface: TokensDarkColors.onSurface,
    onSurfaceVariant: TokensDarkColors.onSurfaceVariant,
    surface: TokensDarkColors.surface,
    background: TokensDarkColors.background,
    surfaceContainerHigh: TokensDarkColors.surfaceContainerHigh,
    primary: TokensDarkColors.primary,
    onPrimary: TokensDarkColors.onPrimary,
    primaryContainer: TokensDarkColors.primaryContainer,
    onPrimaryContainer: TokensDarkColors.onPrimaryContainer,
    secondary: TokensDarkColors.secondary,
    onSecondary: TokensDarkColors.onSecondary,
    secondaryContainer: TokensDarkColors.secondaryContainer,
    onSecondaryContainer: TokensDarkColors.onSecondaryContainer,
    tertiary: TokensDarkColors.tertiary,
    onTertiary: TokensDarkColors.onTertiary,
    tertiaryContainer: TokensDarkColors.tertiaryContainer,
    onTertiaryContainer: TokensDarkColors.onTertiaryContainer,
    error: TokensDarkColors.error,
    onError: TokensDarkColors.onError,
    errorContainer: TokensDarkColors.errorContainer,
    onErrorContainer: TokensDarkColors.onErrorContainer,
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
    outline: TokensDarkColors.outline,
    surfaceContainerLow: TokensDarkColors.surfaceContainerLow,
    navigationBar: TokensDarkColors.navigationBar,
  );

  final Color onSurface, onSurfaceVariant, surface, background;
  final Color surfaceContainerHigh, primary, onPrimary, primaryContainer;
  final Color onPrimaryContainer, secondary, onSecondary, secondaryContainer;
  final Color onSecondaryContainer, tertiary, onTertiary, tertiaryContainer;
  final Color onTertiaryContainer, error, onError, errorContainer;
  final Color onErrorContainer, accent, onAccent, accentContainer;
  final Color onAccentContainer;
  final Color success, warning, calories, sessions, study, streak, outline;
  final Color surfaceContainerLow, navigationBar;
}
