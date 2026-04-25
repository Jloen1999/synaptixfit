import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/supabase_config.dart';
import 'core/design_system/sv_theme.dart';
import 'core/routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SupabaseConfig.initialize();
  runApp(const ProviderScope(child: SynaptixFitApp()));
}

class SynaptixFitApp extends ConsumerWidget {
  const SynaptixFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SynaptixFit',
      debugShowCheckedModeBanner: false,
      theme: SVTheme.lightTheme,
      locale: const Locale('es', 'ES'),
      routerConfig: appRouter,
    );
  }
}
