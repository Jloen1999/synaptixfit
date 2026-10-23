import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../presentation/l10n/gen_l10n/app_localizations.dart';
import '../presentation/screens/auth/session/bloc/session_bloc.dart';
import '../presentation/theme/app_theme.dart';
import '../presentation/widgets/widgets.dart';
import '../routes.dart';
import 'di/app_di.dart';

/// Widget raíz: tema, idioma, sesión global y navegación.
class SynaptixFitApp extends StatefulWidget {
  const SynaptixFitApp({super.key});

  @override
  State<SynaptixFitApp> createState() => _SynaptixFitAppState();
}

class _SynaptixFitAppState extends State<SynaptixFitApp> {
  late final SessionBloc _session = getIt<SessionBloc>()
    ..add(const SessionEvent.started());
  late final GoRouter _router = buildRouter(_session);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _session,
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // Dirección «Deportivo oscuro»: la app arranca en oscuro aunque el
        // sistema esté en claro; el tema claro queda listo para un selector.
        themeMode: ThemeMode.dark,
        routerConfig: _router,
        // Orden de foco con teclado (ver AppFocusGroup): el grupo raíz hace
        // visible el elemento enfocado y cada zona desplazable es un grupo.
        builder: (context, child) => AppFocusGroup(child: child!),
        scrollBehavior: const AppScrollBehavior(),
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
