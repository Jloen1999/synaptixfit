import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/enums/visibility.dart' as vis;
import 'package:synaptixfit/domain/models/training/exercise.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/domain/models/training/session.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/exercise_detail/bloc/exercise_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/live_session/bloc/live_session_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/live_session/page/live_session_page.dart';
import 'package:synaptixfit/presentation/screens/training/widgets/planned_exercise_card.dart';
import 'package:synaptixfit/presentation/screens/training/widgets/routine_summary_card.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'training_fixtures.dart';

class _MockLiveBloc extends MockBloc<LiveSessionEvent, LiveSessionState>
    implements LiveSessionBloc {}

class _MockDetailBloc extends MockBloc<ExerciseDetailEvent, ExerciseDetailState>
    implements ExerciseDetailBloc {}

/// Press banca en pirámide (reps + kg), plancha (segundos) y carrera (min +
/// metros): las tres formas de medir que cambian la tabla de series.
final _bench = TrainingFixtures.planned('p1').copyWith(
  exerciseName: 'Press banca',
  measurementTypes: const [MeasurementType.repetitions, MeasurementType.weight],
  parameters: const ExerciseParameters(
    sets: 3,
    reps: 10,
    repsPerSet: [12, 10, 8],
    weightKg: 40,
    weightsKg: [30, 35, 40],
  ),
);
final _plank = TrainingFixtures.planned('p2', order: 1).copyWith(
  exerciseName: 'Plancha',
  measurementTypes: const [MeasurementType.time],
  parameters: const ExerciseParameters(sets: 3, reps: 1, isometricSeconds: 30),
);
final _run = TrainingFixtures.planned('p3', order: 2).copyWith(
  exerciseName: 'Carrera',
  modality: Modality.aerobic,
  measurementTypes: const [MeasurementType.time],
  parameters: const ExerciseParameters(
    sets: 1,
    reps: 1,
    targetDurationSeconds: 1500,
    distanceMeters: 5000,
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  /// Móvil de 360 × [height] dp: las listas se desplazan y las barras fijas
  /// tienen que caber.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double textScale = 1,
    ThemeData? theme,
    double height = 800,
  }) async {
    tester.view.physicalSize = Size(360, height);
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
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: child,
      ),
    );
    await tester.pump();
  }

  group('tarjeta de ejercicio de la rutina', () {
    Widget cards(List<ExerciseParameters> changes, {bool actions = true}) =>
        Scaffold(
          body: ListView(
            children: [
              for (final e in [_bench, _plank, _run])
                PlannedExerciseCard(
                  exercise: e,
                  position: 1,
                  count: 3,
                  editable: true,
                  onChanged: changes.add,
                  onReplace: actions ? () {} : null,
                  onRemove: actions ? () {} : null,
                  onMoveDown: actions ? () {} : null,
                ),
            ],
          ),
        );

    for (final scale in [1.0, 2.0]) {
      testWidgets('cada ejercicio muestra solo sus campos (texto x$scale)', (
        tester,
      ) async {
        await pump(tester, cards([]), textScale: scale, height: 4000);
        expect(tester.takeException(), isNull);
        // Columnas según la medida: reps + kg, segundos, minutos + metros
        // (con letra grande, la etiqueta va encima de cada cifra).
        expect(find.text('Reps'), findsWidgets);
        expect(find.text('Kg'), findsWidgets);
        expect(find.text('Seg'), findsWidgets);
        expect(find.text('Min'), findsOneWidget);
        expect(find.text('Metros'), findsOneWidget);
        // Acciones con texto, sin menú de tres puntos.
        expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
        expect(find.text('Cambiar'), findsNWidgets(3));
      });
    }

    testWidgets('cambiar una cifra guarda solo esa serie', (tester) async {
      final changes = <ExerciseParameters>[];
      final semantics = tester.ensureSemantics();
      await pump(tester, cards(changes, actions: false));
      // El campo se anuncia con su serie y su medida.
      expect(
        find.bySemanticsLabel(RegExp('Serie 1, repeticiones')),
        findsWidgets,
      );
      semantics.dispose();
      final firstReps = find.byType(TextField).first;
      await tester.tap(firstReps);
      await tester.enterText(firstReps, '15');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(changes, isNotEmpty);
      expect(changes.last.repsPerSet, [15, 10, 8]);
      expect(changes.last.weightsKg, [30, 35, 40]);
    });

    testWidgets('un valor fuera de rango se marca, se explica y no se guarda', (
      tester,
    ) async {
      final changes = <ExerciseParameters>[];
      await pump(tester, cards(changes, actions: false));
      final firstReps = find.byType(TextField).first;
      await tester.tap(firstReps);
      await tester.enterText(firstReps, '500');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(changes, isEmpty);
      expect(find.text('Serie 1: repeticiones entre 1 y 100'), findsOneWidget);
    });
  });

  testWidgets('tarjeta de rutina en curso con fondo y próximo día (x2)', (
    tester,
  ) async {
    await pump(
      tester,
      Scaffold(
        body: ListView(
          children: [
            RoutineSummaryCard(
              routine: const RoutineSummary(
                id: 'r1',
                ownerId: 'u1',
                name: 'Fuerza en casa con un nombre largo',
                visibility: vis.Visibility.private,
                status: RoutineStatus.active,
                durationWeeks: 4,
                exerciseCount: 12,
                totalDays: 12,
                completedDays: 4,
                skippedDays: 1,
                coverModality: Modality.strength,
              ),
              nextDay: PendingDay(
                routineId: 'r1',
                routineName: 'Fuerza',
                weekId: 'w2',
                weekNumber: 2,
                totalWeeks: 4,
                dayId: 'd1',
                dayNumber: 3,
                dayName: 'Tirón',
                dayStatus: ProgressStatus.pending,
                scheduledDate: DateTime(2026, 11, 2),
                overdue: true,
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
      textScale: 2,
      theme: AppTheme.dark,
      height: 1400,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('5/12 días'), findsOneWidget);
    expect(find.textContaining('Tirón'), findsOneWidget);
  });

  group('sesión en vivo', () {
    late _MockLiveBloc bloc;

    setUpAll(() => registerFallbackValue(const LiveSessionEvent.restSkipped()));

    setUp(() {
      bloc = _MockLiveBloc();
      getIt.registerFactory<LiveSessionBloc>(() => bloc);
    });

    tearDown(() => getIt.unregister<LiveSessionBloc>());

    LiveSessionState ready({int? rest}) => LiveSessionState(
      status: LiveStatus.ready,
      sessionId: 's1',
      session: TrainingFixtures.session(
        sets: const [
          SessionSet(
            id: 'x1',
            plannedExerciseId: 'p1',
            setNumber: 1,
            repsDone: 12,
            weightKg: 30,
            completed: true,
          ),
        ],
      ),
      exercises: [_bench, _plank, _run],
      dayNumber: 1,
      routineName: 'Fuerza',
      activeExerciseId: 'p1',
      elapsedSeconds: 600,
      restRemaining: rest,
      restTotal: rest ?? 0,
    );

    for (final (scale, height) in [(1.0, 640.0), (2.0, 640.0), (2.0, 800.0)]) {
      testWidgets(
        'ejercicio actual, serie destacada y siguiente (x$scale, 360×$height)',
        (tester) async {
          when(() => bloc.state).thenReturn(ready());
          await pump(
            tester,
            const LiveSessionPage(sessionId: 's1'),
            textScale: scale,
            height: height,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('0 de 3 ejercicios · 10 min'), findsOneWidget);
          expect(find.text('Press banca'), findsWidgets);
          expect(find.text('Marcar serie 2'), findsOneWidget);
          expect(find.text('Después: Plancha'), findsOneWidget);
          expect(find.text('Finalizar'), findsOneWidget);
          // Con letra grande, «Ejercicio 1 de 3» con anterior y siguiente.
          if (scale > 1) {
            expect(find.byTooltip('Ejercicio siguiente'), findsOneWidget);
          }
          await tester.pumpWidget(const SizedBox());
        },
      );
    }

    // Antes se apilaba la ruta del ejercicio (de la pestaña Entreno) sobre la
    // sesión, que es pantalla completa: go_router duplicaba el armazón y se
    // veía una pantalla oscura. Ahora se abre «Cómo se hace» en una hoja.
    testWidgets('tocar un ejercicio de calentamiento abre su hoja', (
      tester,
    ) async {
      final detail = _MockDetailBloc();
      when(() => detail.state).thenReturn(const ExerciseDetailState.loading());
      getIt.registerFactory<ExerciseDetailBloc>(() => detail);
      addTearDown(() => getIt.unregister<ExerciseDetailBloc>());
      final warmUp = TrainingFixtures.squat.copyWith(previewUrl: null);
      when(() => bloc.state).thenReturn(
        ready().copyWith(
          session: TrainingFixtures.session(),
          bookends: SessionBookends(warmUp: [warmUp]),
        ),
      );
      await pump(tester, const LiveSessionPage(sessionId: 's1'));
      final header = find.text('Calentamiento').first;
      await tester.ensureVisible(header);
      await tester.tap(header);
      await tester.pump(const Duration(milliseconds: 500));
      // La barra fija de abajo puede taparla en 360 dp: se pulsa su acción.
      final tile = find.ancestor(
        of: find.text('Sentadilla').first,
        matching: find.byType(ListTile),
      );
      tester.widget<ListTile>(tile).onTap!();
      // La hoja tiene una animación de carga: no se espera a que pare.
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Sentadilla'),
        ),
        findsWidgets,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('marcar la serie que toca envía lo previsto de esa serie', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(ready());
      await pump(tester, const LiveSessionPage(sessionId: 's1'));
      await tester.tap(find.text('Marcar serie 2'));
      await tester.pump();
      final recorded = verify(
        () => bloc.add(captureAny()),
      ).captured.whereType<LiveSessionSetRecorded>().single.record;
      // La pirámide manda: 10 reps con 35 kg en la serie 2.
      expect(recorded.setNumber, 2);
      expect(recorded.repsDone, 10);
      expect(recorded.weightKg, 35);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('el descanso se ve en grande con −15 s, +15 s y Saltar', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(ready(rest: 75));
      await pump(
        tester,
        const LiveSessionPage(sessionId: 's1'),
        textScale: 2,
        height: 640,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('1:15'), findsOneWidget);
      expect(find.text('−15 s'), findsOneWidget);
      expect(find.text('+15 s'), findsOneWidget);
      expect(find.text('Saltar'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
