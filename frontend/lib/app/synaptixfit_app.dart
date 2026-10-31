import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/enums/app_language.dart';
import '../domain/enums/appearance_mode.dart';
import '../presentation/l10n/gen_l10n/app_localizations.dart';
import '../presentation/screens/auth/session/bloc/session_bloc.dart';
import '../presentation/screens/profile/appearance/bloc/appearance_bloc.dart';
import '../presentation/screens/profile/language/bloc/language_bloc.dart';
import '../presentation/theme/app_theme.dart';
import '../presentation/theme/tokens.g.dart';
import '../presentation/widgets/widgets.dart';
import '../routes.dart';
import 'di/app_di.dart';

/// Widget raíz: tema, idioma, sesión global y navegación.
/// [initialAppearance] e [initialLanguage] se leen antes de `runApp` para
/// pintar ya con el tema y el idioma elegidos.
class SynaptixFitApp extends StatefulWidget {
  const SynaptixFitApp({
    super.key,
    this.initialAppearance,
    this.initialLanguage,
  });

  final AppearanceMode? initialAppearance;
  final AppLanguage? initialLanguage;

  @override
  State<SynaptixFitApp> createState() => _SynaptixFitAppState();
}

class _SynaptixFitAppState extends State<SynaptixFitApp> {
  late final SessionBloc _session = getIt<SessionBloc>()
    ..add(const SessionEvent.started());
  late final GoRouter _router = buildRouter(_session);
  late final AppearanceBloc _appearance = getIt<AppearanceBloc>(
    param1: widget.initialAppearance,
  )..add(const AppearanceEvent.started());
  late final LanguageBloc _language = getIt<LanguageBloc>(
    param1: widget.initialLanguage,
  )..add(const LanguageEvent.started());

  @override
  void dispose() {
    _router.dispose();
    unawaited(_appearance.close());
    unawaited(_language.close());
    super.dispose();
  }

  static ThemeMode _themeMode(AppearanceMode mode) => switch (mode) {
    AppearanceMode.dark => ThemeMode.dark,
    AppearanceMode.light => ThemeMode.light,
    AppearanceMode.system => ThemeMode.system,
  };

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _session),
        BlocProvider.value(value: _appearance),
        BlocProvider.value(value: _language),
      ],
      child: Builder(
        builder: (context) {
          final appearance = context.watch<AppearanceBloc>().state;
          final language = context.watch<LanguageBloc>().state.language;
          return MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context).appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            // Dirección «Deportivo oscuro» por defecto; claro o el del sistema
            // si el usuario lo elige en Ajustes.
            themeMode: _themeMode(appearance.mode),
            // Con «reducir movimiento» el cambio de tema es instantáneo.
            themeAnimationDuration:
                WidgetsBinding
                    .instance
                    .platformDispatcher
                    .accessibilityFeatures
                    .disableAnimations
                ? Duration.zero
                : TokensDuration.normal,
            routerConfig: _router,
            // Orden de foco con teclado (ver AppFocusGroup): el grupo raíz hace
            // visible el elemento enfocado y cada zona desplazable es un grupo.
            // Fechas y números siguen el idioma resuelto (y la cabecera
            // Accept-Language que se envía a la API).
            builder: (context, child) {
              Intl.defaultLocale = Localizations.localeOf(context).languageCode;
              return AppFocusGroup(child: child!);
            },
            scrollBehavior: const AppScrollBehavior(),
            locale: language.languageCode == null
                ? null
                : Locale(language.languageCode!),
            // «Como el dispositivo»: su idioma si está traducido; si no, español.
            localeListResolutionCallback: (locales, supported) => Locale(
              AppLanguage.resolve(
                AppLanguage.system,
                (locales ?? const <Locale>[])
                    .map((l) => l.languageCode)
                    .firstWhere(
                      AppLanguage.supportedCodes.contains,
                      orElse: () => AppLanguage.fallbackCode,
                    ),
              ),
            ),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
