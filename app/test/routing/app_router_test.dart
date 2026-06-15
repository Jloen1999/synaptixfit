import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/core/config/supabase_config.dart';
import 'package:synaptixfit/core/routing/app_router.dart';
import 'package:synaptixfit/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Cargar dotenv y luego limpiar credenciales de Supabase para forzar
    // modo mock (evita dependencia de shared_preferences en tests).
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Archivo .env no disponible; dotenv queda con valores por defecto.
    }
    // Forzar modo mock limpiando las variables de Supabase.
    dotenv.env['SUPABASE_URL'] = '';
    dotenv.env['SUPABASE_ANON_KEY'] = '';
    await SupabaseConfig.initialize();
  });

  testWidgets('Navega desde splash a bienvenida', (WidgetTester tester) async {
    // Tamanio de pantalla de un telefono para evitar overflows.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.reset());

    await tester.pumpWidget(const ProviderScope(child: SynaptixFitApp()));
    appRouter.go('/');
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a SynaptixFit'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('Flujo login mock redirige a onboarding',
      (WidgetTester tester) async {
    // Tamanio de pantalla de un telefono para evitar overflows.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.reset());

    await tester.pumpWidget(const ProviderScope(child: SynaptixFitApp()));
    appRouter.go('/');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'nuevo@correo.com');
    await tester.enterText(find.byType(TextField).at(1), 'Password123');
    await tester.tap(find.text('Iniciar sesión'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Perfil Físico y Bienestar Inicial'), findsOneWidget);
  });
}
