import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/theme/tokens.g.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

/// [AppBackButton]: vuelve si hay pila, va al padre si no (abierta desde un
/// aviso o un enlace), respeta `PopScope` y el lector la anuncia «Volver».
void main() {
  late List<String> popScopeCalls;

  setUp(() => popScopeCalls = []);

  Widget page(String name, {bool guarded = false}) {
    final scaffold = Scaffold(
      appBar: AppPageBar(
        leading: const AppBackButton(fallback: '/padre'),
        title: Text(name),
      ),
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => context.popOrGo('/padre', 'hecho'),
          child: const Text('Salir'),
        ),
      ),
    );
    if (!guarded) return scaffold;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) popScopeCalls.add(name);
      },
      child: scaffold,
    );
  }

  GoRouter router(String initial, {bool guarded = false}) => GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/padre', builder: (_, _) => const Text('Pantalla padre')),
      GoRoute(path: '/origen', builder: (_, _) => const Text('Origen')),
      GoRoute(
        path: '/hija',
        builder: (_, _) => page('Hija', guarded: guarded),
      ),
    ],
  );

  Future<GoRouter> pump(
    WidgetTester tester,
    String initial, {
    bool guarded = false,
  }) async {
    final r = router(initial, guarded: guarded);
    addTearDown(r.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: r,
        theme: AppTheme.light,
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
    await tester.pumpAndSettle();
    return r;
  }

  String location(GoRouter r) =>
      r.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('con pila, vuelve a la pantalla de debajo', (tester) async {
    final r = await pump(tester, '/origen');
    unawaited(r.push('/hija'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(find.text('Origen'), findsOneWidget);
    expect(location(r), '/origen');
  });

  testWidgets('sin pila (aviso, enlace), va con go a su padre', (tester) async {
    final r = await pump(tester, '/hija');

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla padre'), findsOneWidget);
    expect(location(r), '/padre');
  });

  testWidgets('sin pila respeta PopScope: la página decide', (tester) async {
    final r = await pump(tester, '/hija', guarded: true);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(popScopeCalls, ['Hija']);
    expect(location(r), '/hija');
  });

  testWidgets('con pila respeta PopScope igual', (tester) async {
    final r = await pump(tester, '/origen', guarded: true);
    unawaited(r.push('/hija'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(popScopeCalls, ['Hija']);
    // `push` no cambia la dirección: se mira que la página sigue arriba.
    expect(find.text('Hija'), findsOneWidget);
    expect(find.text('Origen'), findsNothing);
  });

  testWidgets('el lector la anuncia como botón «Volver»', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, '/hija');

    final button = find.descendant(
      of: find.byType(AppBackButton),
      matching: find.byType(IconButton),
    );
    expect(
      tester.getSemantics(button),
      // El nombre accesible del IconButton es su tooltip.
      isSemantics(
        tooltip: 'Volver',
        isButton: true,
        hasTapAction: true,
        isEnabled: true,
      ),
    );
    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(AppBackButton),
        matching: find.byType(Icon),
      ),
    );
    expect(icon.icon, AppIcons.back);
    // Área de toque mínima (WCAG 2.5.8): el botón, centrado, no el hueco.
    expect(
      tester.getSize(button),
      const Size.square(TokensLayout.minTouchTarget),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('popOrGo: con pila hace pop con el resultado', (tester) async {
    final r = await pump(tester, '/origen');
    final result = r.push<String>('/hija');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(await result, 'hecho');
    expect(location(r), '/origen');
  });

  testWidgets('popOrGo: sin pila va al padre en vez de fallar', (tester) async {
    final r = await pump(tester, '/hija');

    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(location(r), '/padre');
  });
}
