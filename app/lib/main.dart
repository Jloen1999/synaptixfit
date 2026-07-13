import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'core/config/supabase_config.dart';
import 'core/config/hive_config.dart';
import 'core/design_system/sv_theme.dart';
import 'core/routing/app_router.dart';
import 'core/session_reset.dart';
import 'features/perfil/application/perfil_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('es');
  await HiveConfig.init();
  await SupabaseConfig.initialize();
  runApp(const SynaptixFitRoot());
}

class SynaptixFitRoot extends StatelessWidget {
  const SynaptixFitRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: sessionResetNotifier,
      builder: (context, sessionKey, child) {
        return ProviderScope(
          key: ValueKey(sessionKey),
          child: child!,
        );
      },
      child: const SynaptixFitApp(),
    );
  }
}

class SynaptixFitApp extends ConsumerWidget {
  const SynaptixFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AuthGuard(
      child: MaterialApp.router(
        title: 'SynaptixFit',
        debugShowCheckedModeBanner: false,
        theme: SVTheme.lightTheme,
        locale: const Locale('es', 'ES'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
          Locale('es'),
          Locale('en'),
        ],
        routerConfig: appRouter,
      ),
    );
  }
}

/// Barrera de identidad global (defensa en profundidad).
///
/// Verifica que [perfilUsuarioProvider.usuario.id] coincida con
/// [Supabase.auth.currentUser?.id] antes de renderizar la aplicacion.
class _AuthGuard extends ConsumerWidget {
  const _AuthGuard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabaseUserId = sb.Supabase.instance.client.auth.currentUser?.id;
    final perfilAsync = ref.watch(perfilUsuarioProvider);

    if (supabaseUserId == null) return child;

    final perfilId = perfilAsync.valueOrNull?.usuario.id;
    if (perfilId != null && perfilId != supabaseUserId) {
      return const _SkeletonAppFull();
    }

    if (perfilAsync.isLoading && perfilAsync.hasValue) {
      final prevId = perfilAsync.requireValue.usuario.id;
      if (prevId != supabaseUserId) return const _SkeletonAppFull();
    }

    return child;
  }
}

class _SkeletonAppFull extends StatelessWidget {
  const _SkeletonAppFull();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SVTheme.lightTheme,
      home: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF72FE8F),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Preparando SynaptixFit',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
