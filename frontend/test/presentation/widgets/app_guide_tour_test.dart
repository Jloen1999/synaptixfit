import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

/// `AppGuideTour` (ADR 0049): pasos con «Siguiente (n de N)», «Saltar» y
/// «Entendido», foco en la tarjeta, el lector la lee como diálogo y los pasos
/// sin nada pintado se saltan.
void main() {
  final first = GlobalKey();
  final second = GlobalKey();
  final third = GlobalKey();

  List<AppGuideStep> steps({bool withHidden = false}) => [
    AppGuideStep(target: first, title: 'Tu día', body: 'Lo que toca ahora.'),
    if (withHidden)
      AppGuideStep(
        target: GlobalKey(),
        title: 'Escondido',
        body: 'No está pintado.',
      ),
    AppGuideStep(target: second, title: 'Tu semana', body: 'Toca un día.'),
    AppGuideStep(target: third, title: 'Buscar', body: 'Encuentra algo.'),
  ];

  /// Abre la guía y devuelve cuándo termina.
  Future<Completer<void>> open(
    WidgetTester tester, {
    bool withHidden = false,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final closed = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          appBar: AppBar(
            actions: [
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => showAppGuideTour(
                    context,
                    steps: steps(withHidden: withHidden),
                  ).then((_) => closed.complete()),
                  child: const Text('Abrir'),
                ),
              ),
            ],
          ),
          body: ListView(
            children: [
              SizedBox(key: first, height: 60, child: const Text('Hoy')),
              // Fuera de la vista, pero dentro de lo que la lista ya ha pintado.
              const SizedBox(height: 800),
              SizedBox(key: second, height: 60, child: const Text('Semana')),
              SizedBox(key: third, height: 60, child: const Text('Lupa')),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    return closed;
  }

  testWidgets('avanza paso a paso y termina con «Entendido»', (tester) async {
    final closed = await open(tester);
    expect(find.text('Tu día'), findsOneWidget);
    expect(find.text('Siguiente (1 de 3)'), findsOneWidget);
    expect(find.text('Saltar guía'), findsOneWidget);
    await tester.tap(find.text('Siguiente (1 de 3)'));
    await tester.pumpAndSettle();
    expect(find.text('Tu semana'), findsOneWidget);
    await tester.tap(find.text('Siguiente (2 de 3)'));
    await tester.pumpAndSettle();
    expect(find.text('Buscar'), findsOneWidget);
    // En el último, «Entendido» y sin «Saltar guía».
    expect(find.text('Entendido'), findsOneWidget);
    expect(find.text('Saltar guía'), findsNothing);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(closed.isCompleted, isTrue);
    expect(find.text('Buscar'), findsNothing);
  });

  testWidgets('«Saltar guía» la cierra en cualquier paso', (tester) async {
    final closed = await open(tester);
    await tester.tap(find.text('Saltar guía'));
    await tester.pumpAndSettle();
    expect(closed.isCompleted, isTrue);
    expect(find.text('Tu día'), findsNothing);
  });

  testWidgets('«atrás» también la cierra', (tester) async {
    final closed = await open(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(closed.isCompleted, isTrue);
  });

  testWidgets('el foco va al botón de la tarjeta en cada paso', (tester) async {
    await open(tester);
    FilledButton primary() => tester.widget<FilledButton>(
      find.ancestor(
        of: find.textContaining('Siguiente'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(primary().focusNode!.hasFocus, isTrue);
    await tester.tap(find.text('Siguiente (1 de 3)'));
    await tester.pumpAndSettle();
    expect(primary().focusNode!.hasFocus, isTrue);
  });

  testWidgets('el lector la lee como un diálogo con su paso', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'^Guía, paso 1 de 3: Tu día')),
      ),
      isSemantics(scopesRoute: true, namesRoute: true),
    );
    handle.dispose();
  });

  testWidgets('los pasos sin nada pintado no cuentan', (tester) async {
    await open(tester, withHidden: true);
    expect(find.text('Siguiente (1 de 3)'), findsOneWidget);
    await tester.tap(find.text('Siguiente (1 de 3)'));
    await tester.pumpAndSettle();
    expect(find.text('Escondido'), findsNothing);
    expect(find.text('Tu semana'), findsOneWidget);
  });

  testWidgets('con letra al 200 % cabe sin desbordarse', (tester) async {
    await open(tester, textScale: 2);
    expect(find.text('Tu día'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Siguiente (1 de 3)'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
