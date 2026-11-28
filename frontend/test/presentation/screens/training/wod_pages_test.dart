import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/models/training/wod.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/wod_editor/bloc/wod_editor_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/wod_editor/page/wod_editor_page.dart';
import 'package:synaptixfit/presentation/screens/training/wod_home/bloc/wod_home_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/wod_home/page/wod_home_page.dart';
import 'package:synaptixfit/presentation/screens/training/wod_home/page/wod_result_sheet.dart';
import 'package:synaptixfit/presentation/screens/training/wod_live/bloc/wod_live_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/wod_live/page/wod_live_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

class _MockHome extends MockBloc<WodHomeEvent, WodHomeState>
    implements WodHomeBloc {}

class _MockEditor extends MockBloc<WodEditorEvent, WodEditorState>
    implements WodEditorBloc {}

class _MockLive extends MockBloc<WodLiveEvent, WodLiveState>
    implements WodLiveBloc {}

const _template = Wod(
  templateCode: 'TWO_DUMBBELLS',
  format: WodFormat.amrap,
  timeCapSeconds: 900,
  movements: [
    WodMovement(
      code: 'DUMBBELL_THRUSTER',
      quantity: 10,
      rxKg: 15,
      scaledKg: 7.5,
    ),
    WodMovement(code: 'DUMBBELL_ROW', quantity: 10, rxKg: 15, scaledKg: 7.5),
    WodMovement(code: 'RUN', quantity: 200, unit: WodUnit.meters),
  ],
);

const _mine = Wod(
  id: 'w1',
  title: 'Lunes de piernas con el grupo de la tarde',
  strength: 'Sentadilla trasera 5 × 5',
  format: WodFormat.forTime,
  timeCapSeconds: 900,
  rounds: 3,
  movements: [
    WodMovement(name: 'Sentadillas', quantity: 20),
    WodMovement(name: 'Balanceo con pesa rusa', quantity: 15, rxKg: 16),
  ],
);

WodResult _result({int value = 540, bool capped = false}) => WodResult(
  id: 'r$value',
  wodId: 'w1',
  division: WodDivision.rx,
  scoreType: capped ? WodScoreType.reps : WodScoreType.time,
  value: value,
  capped: capped,
  performedAt: DateTime(2026, 11, 28, 18),
);

/// Pantallas del apartado WOD (ADR 0069): la pizarra, el editor y el WOD en
/// marcha, también a 320 px y con el texto al 200 %.
void main() {
  late _MockHome home;
  late _MockEditor editor;
  late _MockLive live;

  const example = WodHomeState(
    status: WodHomeStatus.ready,
    board: WodBoard(wod: _template, example: true),
    templates: [_template, _mine],
  );
  final own = WodHomeState(
    status: WodHomeStatus.ready,
    board: WodBoard(wod: _mine, bestRx: _result(), todayResult: _result()),
    marks: [
      WodMark(
        result: _result(),
        title: _mine.title,
        format: WodFormat.forTime,
        best: true,
      ),
      WodMark(
        result: _result(value: 96, capped: true),
        templateCode: 'TRIPLE_TEN',
        format: WodFormat.forTime,
      ),
    ],
  );

  setUpAll(() {
    initializeDateFormatting('es');
    registerFallbackValue(const WodHomeEvent.started());
    registerFallbackValue(const WodEditorEvent.deleteRequested('x'));
    registerFallbackValue(const WodLiveEvent.ticked());
  });

  setUp(() {
    home = _MockHome();
    editor = _MockEditor();
    live = _MockLive();
    when(() => editor.state).thenReturn(const WodEditorState());
    // La página comprueba que el bloc sigue vivo al volver de una hoja.
    when(() => home.isClosed).thenReturn(false);
    when(() => live.isClosed).thenReturn(false);
    getIt
      ..registerFactory<WodHomeBloc>(() => home)
      ..registerFactory<WodEditorBloc>(() => editor)
      ..registerFactory<WodLiveBloc>(() => live);
  });

  tearDown(() => getIt.reset());

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    double width = 360,
    double scale = 1,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = Size(width, 2600 * scale);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
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
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: page,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('pizarra', () {
    testWidgets('una plantilla dice que es de ejemplo y se puede editar o '
        'cambiar', (tester) async {
      final handle = tester.ensureSemantics();
      when(() => home.state).thenReturn(example);
      await pump(tester, const WodHomePage());

      expect(find.text('WOD de ejemplo'), findsOneWidget);
      expect(find.text('Dos mancuernas'), findsOneWidget);
      expect(find.text('AMRAP 15 MIN'), findsOneWidget);
      // La cantidad delante y, en Rx, sus kilos.
      expect(
        find.text(
          '10 Sentadilla con empuje (mancuernas) · 15 kg',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('200 m Carrera', findRichText: true), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Cambiar por otro'), findsOneWidget);
      expect(find.text('Añadir mi WOD'), findsOneWidget);
      expect(find.textContaining('Rx = tal cual está escrito'), findsOneWidget);
      expect(find.text('Aún no tienes marca en este WOD'), findsOneWidget);
      // Una sola acción rellena; «Mis marcas» está aunque esté vacío.
      expect(
        find.widgetWithText(FilledButton, 'Empezar cronómetro'),
        findsOneWidget,
      );
      expect(find.text('Mis marcas'), findsOneWidget);
      expect(find.text('Aún no tienes marcas'), findsOneWidget);
      expect(find.text('Apuntar marca'), findsNWidgets(2));

      await tester.tap(find.text('Adaptado'));
      verify(
        () => home.add(const WodHomeEvent.divisionChanged(WodDivision.scaled)),
      ).called(1);
      handle.dispose();
    });

    testWidgets('mi WOD enseña la mejor marca, la de hoy y «Mis marcas»', (
      tester,
    ) async {
      when(() => home.state).thenReturn(own);
      await pump(tester, const WodHomePage());

      expect(find.text('WOD de ejemplo'), findsNothing);
      expect(find.text('Cambiar por otro'), findsNothing);
      expect(find.text('3 RONDAS'), findsOneWidget);
      expect(find.text('Límite: 15 min'), findsOneWidget);
      expect(find.text('Fuerza: Sentadilla trasera 5 × 5'), findsOneWidget);
      expect(find.text('Tu mejor marca: 9:00'), findsOneWidget);
      expect(find.text('Hoy: 9:00 · Rx'), findsOneWidget);
      expect(find.text('Mejor marca'), findsOneWidget);
      expect(find.text('Sin terminar: 96 repeticiones · Rx'), findsOneWidget);
      // La marca de una plantilla se nombra con el nombre de la plantilla.
      expect(find.text('Triple diez'), findsOneWidget);
    });

    testWidgets('«Apuntar marca» pide lo del formato y la manda', (
      tester,
    ) async {
      when(() => home.state).thenReturn(own);
      await pump(tester, const WodHomePage());
      await tester.tap(find.widgetWithText(OutlinedButton, 'Apuntar marca'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cómo te fue?'), findsOneWidget);
      // Sin escribir nada no se guarda: se dice por qué.
      await tester.tap(find.text('Guardar marca'));
      await tester.pump();
      expect(find.text('Escribe tu marca para guardarla.'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Minutos'), '8');
      await tester.enterText(find.widgetWithText(TextField, 'Segundos'), '30');
      await tester.tap(find.text('Guardar marca'));
      await tester.pumpAndSettle();
      verify(
        () => home.add(
          const WodHomeEvent.resultSubmitted(
            _mine,
            WodResultDraft(division: WodDivision.rx, value: 510),
          ),
        ),
      ).called(1);
    });

    for (final (name, state) in [('ejemplo', example), ('mío', own)]) {
      testWidgets('$name: a 320 px y con el texto al 200 % no se desborda', (
        tester,
      ) async {
        when(() => home.state).thenReturn(state);
        await pump(tester, const WodHomePage(), width: 320, scale: 2);
        expect(tester.takeException(), isNull);
      });

      for (final theme in [AppTheme.light, AppTheme.dark]) {
        testWidgets('$name: objetivos táctiles y etiquetas '
            '(${theme.brightness.name})', (tester) async {
          final handle = tester.ensureSemantics();
          when(() => home.state).thenReturn(state);
          await pump(tester, const WodHomePage(), theme: theme);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          if (theme == AppTheme.dark) {
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          }
          handle.dispose();
        });
      }
    }
  });

  group('hoja de la marca', () {
    Future<WodResultDraft?> open(
      WidgetTester tester,
      Wod wod, {
      int? elapsed,
      bool timeUp = false,
    }) async {
      WodResultDraft? draft;
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => draft = await showWodResultSheet(
                context,
                wod: wod,
                division: WodDivision.scaled,
                elapsedSeconds: elapsed,
                timeUp: timeUp,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
        width: 320,
        scale: 2,
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Guardar marca'));
      await tester.tap(find.text('Guardar marca'));
      await tester.pumpAndSettle();
      return draft;
    }

    testWidgets('con cronómetro el tiempo ya viene puesto', (tester) async {
      final draft = await open(tester, _mine, elapsed: 432);
      expect(
        draft,
        const WodResultDraft(
          division: WodDivision.scaled,
          value: 432,
          durationSeconds: 432,
        ),
      );
    });

    testWidgets('si se acabó el tiempo pide repeticiones', (tester) async {
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showWodResultSheet(
                context,
                wod: _mine,
                division: WodDivision.rx,
                elapsedSeconds: 900,
                timeUp: true,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Repeticiones'), findsOneWidget);
      expect(find.text('Minutos'), findsNothing);
      expect(
        find.text('Apunta las repeticiones que llevabas.'),
        findsOneWidget,
      );
    });

    testWidgets('AMRAP pide rondas y repeticiones de más', (tester) async {
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showWodResultSheet(
                context,
                wod: _template,
                division: WodDivision.rx,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Rondas completas'), findsOneWidget);
      expect(find.text('Repeticiones de más'), findsOneWidget);
      expect(find.text('No terminé a tiempo'), findsNothing);
    });
  });

  group('editor', () {
    testWidgets('partir de una plantilla: nombres en mi idioma y el código se '
        'conserva si no se toca', (tester) async {
      await pump(tester, const WodEditorPage(wod: _template));
      expect(find.text('Mi WOD'), findsOneWidget);
      expect(find.text('Dos mancuernas'), findsOneWidget);
      expect(find.text('Sentadilla con empuje (mancuernas)'), findsOneWidget);
      expect(find.text('Eliminar WOD'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextField, 'Remo con mancuerna'),
        'Remo con goma',
      );
      await tester.ensureVisible(find.text('Guardar WOD'));
      await tester.tap(find.text('Guardar WOD'));
      final saved =
          verify(() => editor.add(captureAny())).captured.single
              as WodEditorSaveRequested;
      expect(saved.wod.id, isNull);
      expect(saved.wod.templateCode, 'TWO_DUMBBELLS');
      expect(saved.wod.title, 'Dos mancuernas');
      expect(saved.wod.format, WodFormat.amrap);
      expect(saved.wod.timeCapSeconds, 900);
      expect(saved.wod.rounds, isNull);
      expect(saved.wod.movements[0].code, 'DUMBBELL_THRUSTER');
      expect(saved.wod.movements[0].name, isNull);
      expect(saved.wod.movements[0].scaledKg, 7.5);
      expect(saved.wod.movements[1].code, isNull);
      expect(saved.wod.movements[1].name, 'Remo con goma');
      expect(saved.wod.movements[2].unit, WodUnit.meters);
    });

    testWidgets('desde cero no se guarda sin un movimiento con nombre', (
      tester,
    ) async {
      await pump(tester, const WodEditorPage());
      await tester.ensureVisible(find.text('Guardar WOD'));
      await tester.tap(find.text('Guardar WOD'));
      await tester.pump();
      expect(
        find.text('Añade al menos un movimiento con nombre.'),
        findsOneWidget,
      );
      verifyNever(() => editor.add(any()));
    });

    testWidgets('mi WOD: a 320 px y con el texto al 200 % no se desborda', (
      tester,
    ) async {
      await pump(tester, const WodEditorPage(wod: _mine), width: 320, scale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Editar WOD'), findsOneWidget);
      expect(find.text('Eliminar WOD', skipOffstage: false), findsOneWidget);
    });
  });

  group('WOD en marcha', () {
    const running = WodLiveState(
      wod: _mine,
      status: WodLiveStatus.running,
      elapsedSeconds: 125,
    );

    testWidgets('el póster enseña el formato, el reloj y los dos botones', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      when(() => live.state).thenReturn(running);
      await pump(
        tester,
        const WodLivePage(args: (wod: _mine, division: WodDivision.rx)),
      );

      expect(find.text('3 RONDAS'), findsOneWidget);
      expect(find.text('2:05'), findsOneWidget);
      expect(find.text('Llevas'), findsOneWidget);
      expect(find.text('Pausa'), findsOneWidget);
      expect(find.text('Terminar'), findsOneWidget);
      expect(
        find.text('15 Balanceo con pesa rusa · 16 kg', findRichText: true),
        findsOneWidget,
      );
      // El reloj no es una región viva: el lector no lo lee cada segundo.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Cronómetro: 2:05')),
        isNot(isSemantics(isLiveRegion: true)),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      await tester.tap(find.text('Pausa'));
      verify(() => live.add(const WodLiveEvent.pauseToggled())).called(1);
      await tester.tap(find.text('Terminar'));
      verify(() => live.add(const WodLiveEvent.finishRequested())).called(1);
      handle.dispose();
    });

    testWidgets('Tabata en descanso, en pausa y a 320 px con el texto al '
        '200 %', (tester) async {
      const tabata = Wod(
        templateCode: 'FOUR_MINUTES',
        format: WodFormat.tabata,
        timeCapSeconds: 240,
        rounds: 8,
        movements: [WodMovement(code: 'AIR_SQUAT')],
      );
      when(() => live.state).thenReturn(
        const WodLiveState(
          wod: tabata,
          status: WodLiveStatus.running,
          elapsedSeconds: 53,
        ),
      );
      await pump(
        tester,
        const WodLivePage(args: (wod: tabata, division: WodDivision.rx)),
        width: 320,
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Descanso · Ronda 2 de 8'), findsOneWidget);
      expect(find.text('0:07'), findsOneWidget);
      expect(
        find.text('Las que puedas Sentadillas', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('abierta en frío, sin WOD, lleva de vuelta al apartado', (
      tester,
    ) async {
      await pump(tester, const WodLivePage());
      expect(find.text('No hay ningún WOD en marcha'), findsOneWidget);
      expect(find.text('Ir a WOD'), findsOneWidget);
    });
  });
}
