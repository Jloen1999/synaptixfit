import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/core/config/supabase_config.dart';
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

  testWidgets('La app inicia y renderiza MaterialApp.router',
      (WidgetTester tester) async {
    // Tamanio de pantalla de un telefono comun para evitar overflows.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.reset();
    });
    await tester.pumpWidget(const ProviderScope(child: SynaptixFitApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
