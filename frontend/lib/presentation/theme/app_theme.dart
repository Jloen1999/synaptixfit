import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';
import 'tokens.g.dart';

/// Temas claro y oscuro construidos a partir de los tokens de diseño, con la
/// dirección «Deportivo oscuro» (la app arranca en oscuro). Fija el aspecto de
/// todos los componentes de Material para que las pantallas no tengan que
/// repetir colores, radios ni tamaños.
abstract final class AppTheme {
  static ThemeData get light => _build(
    Brightness.light,
    const ColorScheme(
      brightness: Brightness.light,
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
      surface: TokensLightColors.surface,
      onSurface: TokensLightColors.onSurface,
      onSurfaceVariant: TokensLightColors.onSurfaceVariant,
      surfaceContainerLowest: TokensLightColors.surface,
      surfaceContainerLow: TokensLightColors.surfaceContainerLow,
      surfaceContainer: TokensLightColors.surfaceContainer,
      surfaceContainerHigh: TokensLightColors.surfaceContainerHigh,
      surfaceContainerHighest: TokensLightColors.surfaceContainerHigh,
      outline: TokensLightColors.outline,
      outlineVariant: TokensLightColors.outlineVariant,
    ),
    TokensLightColors.background,
    AppPalette.light,
    navigationBar: TokensLightColors.navigationBar,
    buttonOutline: TokensLightColors.buttonOutline,
  );

  static ThemeData get dark => _build(
    Brightness.dark,
    const ColorScheme(
      brightness: Brightness.dark,
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
      surface: TokensDarkColors.surface,
      onSurface: TokensDarkColors.onSurface,
      onSurfaceVariant: TokensDarkColors.onSurfaceVariant,
      surfaceContainerLowest: TokensDarkColors.background,
      surfaceContainerLow: TokensDarkColors.surfaceContainerLow,
      surfaceContainer: TokensDarkColors.surfaceContainer,
      surfaceContainerHigh: TokensDarkColors.surfaceContainerHigh,
      surfaceContainerHighest: TokensDarkColors.surfaceContainerHigh,
      outline: TokensDarkColors.outline,
      outlineVariant: TokensDarkColors.outlineVariant,
    ),
    TokensDarkColors.background,
    AppPalette.dark,
    navigationBar: TokensDarkColors.navigationBar,
    buttonOutline: TokensDarkColors.buttonOutline,
  );

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    final body = GoogleFonts.getTextTheme(TokensFont.body, base);
    final display = GoogleFonts.getTextTheme(TokensFont.display, base);
    // Títulos con interletrado ligeramente negativo: más compactos y legibles
    // en tamaños grandes, que es lo que da el aspecto «editorial».
    TextStyle? heading(TextStyle? style, FontWeight weight, double spacing) =>
        style?.copyWith(fontWeight: weight, letterSpacing: spacing);
    return body
        .copyWith(
          displayLarge: heading(display.displayLarge, FontWeight.w800, -1.2),
          displayMedium: heading(display.displayMedium, FontWeight.w800, -1),
          displaySmall: heading(display.displaySmall, FontWeight.w800, -0.8),
          headlineLarge: heading(display.headlineLarge, FontWeight.w800, -0.6),
          headlineMedium: heading(
            display.headlineMedium,
            FontWeight.w800,
            -0.5,
          ),
          // Cifras y títulos de tarjeta en 800: el peso, no el tamaño, da el
          // aire deportivo sin romper maquetas con el texto al 200 %.
          headlineSmall: heading(display.headlineSmall, FontWeight.w800, -0.4),
          titleLarge: heading(display.titleLarge, FontWeight.w700, -0.2),
          titleMedium: heading(display.titleMedium, FontWeight.w700, -0.1),
          titleSmall: heading(display.titleSmall, FontWeight.w700, 0),
          bodyLarge: body.bodyLarge?.copyWith(height: 1.5),
          bodyMedium: body.bodyMedium?.copyWith(height: 1.45),
          bodySmall: body.bodySmall?.copyWith(height: 1.4),
          labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          labelMedium: body.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }

  static ThemeData _build(
    Brightness brightness,
    ColorScheme scheme,
    Color background,
    AppPalette palette, {
    required Color navigationBar,
    required Color buttonOutline,
  }) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    // `base.textTheme` solo trae colores: los tamaños se añaden después al
    // localizar el tema. Se mezclan ya para que los estilos que se guardan en
    // los temas de componentes (barra superior, botones…) tengan tamaño.
    final textTheme = _textTheme(
      base.typography.englishLike.merge(base.textTheme),
      scheme,
    );

    const cardRadius = BorderRadius.all(Radius.circular(TokensRadius.l));
    const fieldRadius = BorderRadius.all(Radius.circular(TokensRadius.m));
    const buttonSize = Size(
      TokensLayout.minTouchTarget,
      TokensSize.controlHeight,
    );
    final buttonText = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    );

    // Anillo de foco de teclado (WCAG 2.4.7): el resaltado por defecto de
    // Material 3 es un velo del 10 % que apenas se nota sobre botones rellenos.
    // Va por fuera del botón para contrastar con el fondo, sea cual sea su
    // color de relleno; sin foco se mantiene el borde de reposo ([rest]).
    const focusWidth = TokensSize.focusRing;
    WidgetStateProperty<BorderSide?> focusRing([BorderSide? rest]) =>
        WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? BorderSide(
                  color: scheme.onSurface,
                  width: focusWidth,
                  strokeAlign: BorderSide.strokeAlignOutside,
                )
              : rest,
        );

    // Chips y botones segmentados: el borde de reposo se engrosa con el foco.
    BorderSide focusedOr(Set<WidgetState> states, BorderSide rest) =>
        states.contains(WidgetState.focused)
        ? BorderSide(color: scheme.onSurface, width: focusWidth)
        : rest;

    // Indicador del destino activo casi invisible: la selección ya se marca
    // con el color primario, el icono relleno y la etiqueta en negrita.
    final navIndicator = scheme.primary.withValues(alpha: 0.12);
    Color navColor(Set<WidgetState> states) =>
        states.contains(WidgetState.selected)
        ? scheme.primary
        : scheme.onSurfaceVariant;

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      extensions: [palette],
      // En web y escritorio Material encoge los objetivos táctiles por defecto;
      // se fuerzan los 48 dp en todas las plataformas (WCAG 2.5.8).
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _MotionAware(
            FadeForwardsPageTransitionsBuilder(),
          ),
          TargetPlatform.iOS: _MotionAware(CupertinoPageTransitionsBuilder()),
          TargetPlatform.macOS: _MotionAware(CupertinoPageTransitionsBuilder()),
          TargetPlatform.windows: _MotionAware(
            FadeForwardsPageTransitionsBuilder(),
          ),
          TargetPlatform.linux: _MotionAware(
            FadeForwardsPageTransitionsBuilder(),
          ),
          TargetPlatform.fuchsia: _MotionAware(
            FadeForwardsPageTransitionsBuilder(),
          ),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: TokensSize.toolbarHeight,
        titleSpacing: TokensSpacing.m,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.l),
          shape: const StadiumBorder(),
          textStyle: buttonText,
        ).copyWith(side: focusRing()),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.l),
          foregroundColor: scheme.onSurface,
          shape: const StadiumBorder(),
          textStyle: buttonText,
          // Contorno discreto: el texto ya identifica el botón (WCAG 1.4.11
          // no exige 3:1 al borde de un botón con etiqueta visible).
        ).copyWith(side: focusRing(BorderSide(color: buttonOutline))),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonSize,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: buttonText,
        ).copyWith(side: focusRing()),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            TokensLayout.minTouchTarget,
            TokensLayout.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.sm),
          shape: const StadiumBorder(),
          textStyle: buttonText,
        ).copyWith(side: focusRing()),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(TokensLayout.minTouchTarget),
        ).copyWith(side: focusRing()),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 3,
        highlightElevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(TokensRadius.l)),
        ),
        extendedTextStyle: buttonText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Superficie elevada: el campo se distingue de la tarjeta que lo
        // contiene también en oscuro.
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TokensSpacing.m,
          vertical: TokensSpacing.m,
        ),
        // El borde visible (3:1 contra el fondo) indica dónde está el campo
        // sin depender solo del relleno (WCAG 1.4.11).
        border: fieldBorder(scheme.outline),
        enabledBorder: fieldBorder(scheme.outline),
        disabledBorder: fieldBorder(scheme.outlineVariant),
        focusedBorder: fieldBorder(scheme.primary, 2),
        errorBorder: fieldBorder(scheme.error),
        focusedErrorBorder: fieldBorder(scheme.error, 2),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => textTheme.bodyMedium!.copyWith(
            color: states.contains(WidgetState.error)
                ? scheme.error
                : states.contains(WidgetState.focused)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        errorMaxLines: 3,
        helperMaxLines: 3,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: WidgetStateBorderSide.resolveWith(
          (states) => focusedOr(
            states,
            BorderSide(
              color: states.contains(WidgetState.selected)
                  ? scheme.primary
                  : buttonOutline,
            ),
          ),
        ),
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.xs),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.square(TokensLayout.minTouchTarget),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => focusedOr(states, BorderSide(color: scheme.outline)),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          // Seleccionado en el color primario: con el contenedor el cambio de
          // relleno no llegaba a 3:1 (WCAG 1.4.11) y los segmentos no llevan check.
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.surfaceContainerLow,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface,
          ),
        ),
      ),
      // La línea superior de la barra (outlineVariant) la pinta MainShellPage.
      // El foco del teclado: el velo de Material sobre `navigationBar` no se
      // distingue y el tema no admite un borde según el estado, así que cada
      // destino lleva `AppNavFocusRing` (anillo `onSurface` de `focusRing`).
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navigationBar,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: navIndicator,
        elevation: 0,
        height: TokensSize.navBarHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: navColor(states)),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: navColor(states),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: navigationBar,
        indicatorColor: navIndicator,
        elevation: 0,
        labelType: NavigationRailLabelType.all,
        minWidth: TokensSize.railWidth,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        minVerticalPadding: TokensSpacing.sm,
        contentPadding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
        shape: const RoundedRectangleBorder(borderRadius: fieldRadius),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
        circularTrackColor: scheme.surfaceContainerHigh,
        linearMinHeight: TokensSize.progressBar,
        borderRadius: const BorderRadius.all(
          Radius.circular(TokensRadius.pill),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        constraints: const BoxConstraints(
          maxWidth: TokensLayout.readingMaxWidth,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TokensRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(TokensRadius.xl)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: fieldRadius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      // En claro el aviso va invertido (oscuro con acción lima); en oscuro,
      // sobre la superficie más alta con borde, para no deslumbrar.
      snackBarTheme: brightness == Brightness.light
          ? SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: scheme.onSurface,
              contentTextStyle: textTheme.bodyMedium?.copyWith(
                color: scheme.surface,
              ),
              actionTextColor: TokensDarkColors.primary,
              closeIconColor: scheme.surface,
              shape: const RoundedRectangleBorder(borderRadius: fieldRadius),
            )
          : SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: scheme.surfaceContainerHigh,
              contentTextStyle: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
              actionTextColor: scheme.primary,
              closeIconColor: scheme.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: fieldRadius,
                side: BorderSide(color: buttonOutline),
              ),
            ),
      tooltipTheme: TooltipThemeData(
        waitDuration: TokensDuration.tooltipWait,
        textStyle: textTheme.labelMedium?.copyWith(color: scheme.surface),
        decoration: BoxDecoration(
          color: scheme.onSurface,
          borderRadius: const BorderRadius.all(Radius.circular(TokensRadius.s)),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}

/// Usa la transición de [_delegate] salvo que el sistema pida reducir el
/// movimiento: entonces la página aparece sin animación (WCAG 2.3.3).
class _MotionAware extends PageTransitionsBuilder {
  const _MotionAware(this._delegate);

  final PageTransitionsBuilder _delegate;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return _delegate.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
