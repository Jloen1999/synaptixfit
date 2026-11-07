import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

/// Componentes compartidos de la revisión de diseño: esqueletos anunciados,
/// pastilla única, rejilla de accesos y contorno de foco.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double width = 390,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('AppSkeletonList se anuncia una sola vez como «Cargando»', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const AppSkeletonList(count: 3));
    expect(
      find.bySemanticsLabel('Cargando'),
      findsOneWidget,
      reason: 'los bloques son mudos; el grupo habla una vez',
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Cargando')),
      matchesSemantics(label: 'Cargando', isLiveRegion: true),
    );
    handle.dispose();
  });

  testWidgets('AppPill: texto e icono del mismo color y sin desbordar', (
    tester,
  ) async {
    await pump(
      tester,
      const Center(
        child: SizedBox(
          width: 120,
          child: AppPill(
            label: 'Una etiqueta bastante larga para el ancho',
            icon: Icons.flag_outlined,
            color: Colors.teal,
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style?.color, Colors.teal);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppTileGrid pasa a filas de dos con el texto al 200 %', (
    tester,
  ) async {
    List<Widget> tiles() => [
      for (var i = 0; i < 4; i++) Text('Acceso $i', key: ValueKey(i)),
    ];
    await pump(tester, AppTileGrid(children: tiles()));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey(3))).dy,
      tester.getTopLeft(find.byKey(const ValueKey(0))).dy,
      reason: 'al 100 % caben los cuatro en una fila',
    );

    await pump(tester, AppTileGrid(children: tiles()), textScale: 2);
    final first = tester.getTopLeft(find.byKey(const ValueKey(0)));
    expect(tester.getTopLeft(find.byKey(const ValueKey(1))).dy, first.dy);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey(2))).dy,
      greaterThan(first.dy),
    );
  });

  testWidgets('AppFocusOutline dibuja el anillo solo con el foco', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    // Modo teclado: es cuando se ve el anillo.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await pump(
      tester,
      Center(
        child: AppFocusOutline(
          child: InkWell(
            focusNode: focus,
            onTap: () {},
            child: const SizedBox.square(dimension: 48),
          ),
        ),
      ),
    );
    Border? border() =>
        (tester
                        .widget<DecoratedBox>(
                          find
                              .descendant(
                                of: find.byType(AppFocusOutline),
                                matching: find.byType(DecoratedBox),
                              )
                              .first,
                        )
                        .decoration
                    as BoxDecoration)
                .border
            as Border?;
    expect(border(), isNull);
    focus.requestFocus();
    await tester.pump();
    expect(border()?.top.width, 2);

    // Con el dedo no queda el recuadro aunque el foco siga dentro.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    await tester.pump();
    expect(border(), isNull);
  });

  testWidgets(
    'AppStepperField: en el extremo el foco pasa al botón contrario',
    (tester) async {
      var value = 4;
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => AppStepperField(
            label: 'Semanas',
            value: value,
            min: 2,
            max: 5,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      );
      final increase = find.byTooltip('Aumentar Semanas');
      final decrease = find.byTooltip('Reducir Semanas');
      Focus.of(tester.element(find.byIcon(Icons.add_rounded))).requestFocus();
      await tester.pump();
      await tester.tap(increase);
      await tester.pump();
      expect(value, 5);
      final decreaseButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.remove_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(decreaseButton.focusNode!.hasFocus, isTrue);
      expect(find.bySemanticsLabel(RegExp('Semanas')), findsWidgets);
      expect(decrease, findsOneWidget);
    },
  );
}
