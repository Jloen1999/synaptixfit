import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/core/routing/app_router.dart';
import 'package:synaptixfit/main.dart';

void main() {
  testWidgets('Navega desde splash a bienvenida', (WidgetTester tester) async {
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
