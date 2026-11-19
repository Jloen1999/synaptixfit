import 'package:bloc_test/bloc_test.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/models/training/recommendation.dart';
import 'package:synaptixfit/domain/enums/visibility.dart' as vis;
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/domain/models/training/session.dart';
import 'package:synaptixfit/domain/models/training/training_week.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/today_adaptation.dart';
import 'package:synaptixfit/domain/use_cases/training/get_today_adaptation_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/submit_quick_check_in_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/quick_check_in/bloc/quick_check_in_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/training_home/bloc/training_home_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/training_home/page/training_home_page.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';
import 'package:synaptixfit/presentation/screens/training/widgets/continue_session_target.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'training_fixtures.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/use_cases/sync/watch_data_changes_use_case.dart';

/// Contraste por píxeles sin los atajos de Gimnasio (`TrainingQuickActions`).
///
/// El nodo de cada atajo junta el círculo del icono y una etiqueta corta; en el
/// CI (Linux, sin las fuentes) la regla muestrea el borde suavizado de «Más» y da
/// 2,29:1, un falso positivo (como en `reminder_options_test`). La etiqueta es
/// onSurface sobre la superficie, cuyo contraste prueba `contrast_test`; el resto
/// de la pantalla se sigue midiendo por píxeles.
class _ContrastWithoutQuickActions extends MinimumTextContrastGuideline {
  const _ContrastWithoutQuickActions();

  static const _quickActions = {
    'Sesión libre',
    'Plantillas',
    'Ejercicios',
    'Historial',
    'Más',
  };

  @override
  bool shouldSkipNode(SemanticsData data) =>
      super.shouldSkipNode(data) || _quickActions.contains(data.label);
}

/// Sin cambios de datos de otras pantallas.
class _NoDataChanges implements WatchDataChangesUseCaseContract {
  @override
  Stream<Set<DataTopic>> call({required Set<DataTopic> topics}) =>
      const Stream.empty();
}

class _DoneToday implements GetTodayAdaptationUseCaseContract {
  @override
  Future<AppResult<TodayAdaptation>> call() async =>
      const Result.success(TodayAdaptation(checkInDone: true));
}

class _NotYetToday implements GetTodayAdaptationUseCaseContract {
  @override
  Future<AppResult<TodayAdaptation>> call() async =>
      const Result.success(TodayAdaptation(checkInDone: false));
}

class _NoSubmit implements SubmitQuickCheckInUseCaseContract {
  @override
  Future<AppResult<Unit>> call(QuickCheckIn input) async =>
      const Result.success(unit);
}

class _MockTrainingHomeBloc
    extends MockBloc<TrainingHomeEvent, TrainingHomeState>
    implements TrainingHomeBloc {}

ExerciseAdjustment _adjustment(String name) => ExerciseAdjustment(
  exerciseName: name,
  parameters: const ExerciseParameters(sets: 4, reps: 8),
);

final _recommendations = [
  Recommendation(
    id: 'r1',
    type: RecommendationType.progression,
    title: 'Sube la carga',
    description: 'Completaste todas las series con RPE bajo.',
    applied: false,
    adjustments: [
      _adjustment('Sentadilla'),
      _adjustment('Press banca'),
      _adjustment('Remo'),
    ],
  ),
  const Recommendation(
    id: 'r2',
    type: RecommendationType.deload,
    title: 'Semana de descarga',
    applied: false,
  ),
];

void main() {
  late _MockTrainingHomeBloc bloc;

  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    bloc = _MockTrainingHomeBloc();
    when(() => bloc.state).thenReturn(
      TrainingHomeState(
        status: HomeStatus.ready,
        recommendations: _recommendations,
      ),
    );
    getIt
      ..registerFactory<TrainingHomeBloc>(() => bloc)
      // La tarjeta del registro rápido: hoy ya está hecho y sin adaptar.
      ..registerFactory<QuickCheckInBloc>(
        () => QuickCheckInBloc(
          getAdaptation: _DoneToday(),
          submit: _NoSubmit(),
          watchDataChanges: _NoDataChanges(),
        ),
      );
  });

  setUp(() => getIt.registerLazySingleton(ContinueSessionTarget.new));

  tearDown(() {
    getIt
      ..unregister<TrainingHomeBloc>()
      ..unregister<QuickCheckInBloc>()
      ..unregister<ContinueSessionTarget>();
  });

  Future<void> pump(
    WidgetTester tester, {
    ThemeData? theme,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(390, 2400 * textScale);
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
        home: const TrainingHomePage(),
      ),
    );
    await tester.pump();
  }

  /// Las sugerencias van plegadas en «Ver sugerencias» (ADR 0039).
  Future<void> showSuggestions(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, 'Ver sugerencias'));
    // Sin pumpAndSettle: una tarjeta en carga tiene un indicador que no para.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('la sugerencia se despliega y anuncia su estado', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    await showSuggestions(tester);

    // Plegada: sin el porqué y con el resto de ejercicios resumido.
    expect(
      find.text('Completaste todas las series con RPE bajo.'),
      findsNothing,
    );
    expect(find.text('y 1 ejercicio más'), findsOneWidget);
    expect(
      tester.getSemantics(find.widgetWithText(TextButton, 'Ver detalle')),
      isSemantics(
        label: 'Ver detalle',
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
        hasTapAction: true,
      ),
    );

    // Un toque en la tarjeta también la despliega.
    await tester.tap(find.text('Sube la carga'));
    await tester.pumpAndSettle();

    expect(
      find.text('Completaste todas las series con RPE bajo.'),
      findsOneWidget,
    );
    expect(find.text('Remo'), findsOneWidget);
    expect(find.text('y 1 ejercicio más'), findsNothing);
    expect(
      tester
          .getSemantics(find.widgetWithText(TextButton, 'Ver menos').first)
          .flagsCollection
          .isExpanded,
      Tristate.isTrue,
    );
    semantics.dispose();
  });

  testWidgets('las sugerencias van plegadas y «Ver sugerencias» lo anuncia', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    final seeAll = find.widgetWithText(TextButton, 'Ver sugerencias');
    expect(
      tester.getSemantics(seeAll).flagsCollection.isExpanded,
      Tristate.isFalse,
    );
    expect(find.text('Sube la carga'), findsNothing);
    expect(find.text('Semana de descarga'), findsNothing);

    await tester.tap(seeAll);
    await tester.pumpAndSettle();

    expect(find.text('Semana de descarga'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.widgetWithText(TextButton, 'Ver menos').first)
          .flagsCollection
          .isExpanded,
      Tristate.isTrue,
    );
    semantics.dispose();
  });

  testWidgets('«Aplicar» en carga se anuncia como «Cargando»', (tester) async {
    when(() => bloc.state).thenReturn(
      TrainingHomeState(
        status: HomeStatus.ready,
        recommendations: _recommendations,
        busyIds: const {'r1'},
      ),
    );
    final semantics = tester.ensureSemantics();
    await pump(tester);
    await showSuggestions(tester);

    expect(find.bySemanticsLabel('Aplicar, Cargando'), findsOneWidget);
    semantics.dispose();
  });

  group('accesibilidad', () {
    testWidgets('cumple las guías de tamaño táctil, etiquetas y contraste', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await pump(tester, theme: theme);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(const _ContrastWithoutQuickActions()));
      }
      semantics.dispose();
    });

    testWidgets('con el texto al 200 % no se corta ni se solapa', (
      tester,
    ) async {
      await pump(tester, textScale: 2);
      await showSuggestions(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Ver detalle'));
      await tester.pumpAndSettle();

      expect(find.text('Sube la carga'), findsOneWidget);
      expect(find.text('Remo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('avance de la rutina (accesibilidad)', () {
    final overdue = TrainingHomeState(
      status: HomeStatus.ready,
      pendingDay: PendingDay(
        routineId: 'r1',
        routineName: 'Fuerza',
        weekId: 'w1',
        weekNumber: 2,
        totalWeeks: 4,
        dayId: 'd1',
        dayNumber: 3,
        dayName: 'Tirón',
        dayStatus: ProgressStatus.pending,
        scheduledDate: DateTime(2026, 11, 2),
        overdue: true,
        sessionOfWeek: 2,
        sessionsInWeek: 3,
      ),
      staleSessions: [
        OpenSession(
          session: TrainingFixtures.session(),
          stale: true,
          routineName: 'Fuerza',
          dayNumber: 1,
          dayName: 'Empuje',
        ),
      ],
    );
    const finished = TrainingHomeState(
      status: HomeStatus.ready,
      routines: [
        RoutineSummary(
          id: 'r1',
          ownerId: 'u1',
          name: 'Fuerza',
          visibility: vis.Visibility.private,
          status: RoutineStatus.completed,
          durationWeeks: 4,
          exerciseCount: 12,
          totalDays: 12,
          completedDays: 12,
        ),
      ],
    );

    for (final (name, state) in [
      ('día atrasado y sesión abandonada', overdue),
      ('ciclo terminado', finished),
    ]) {
      testWidgets('$name: táctil, etiquetas, contraste y texto al 200 %', (
        tester,
      ) async {
        when(() => bloc.state).thenReturn(state);
        final semantics = tester.ensureSemantics();
        for (final theme in [AppTheme.light, AppTheme.dark]) {
          await pump(tester, theme: theme);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(const _ContrastWithoutQuickActions()));
        }
        await pump(tester, textScale: 2);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  });

  group('Gimnasio al grano (ADR 0055)', () {
    final today = DateUtils.dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final state = TrainingHomeState(
      status: HomeStatus.ready,
      pendingDay: PendingDay(
        routineId: 'r1',
        routineName: 'Cuerpo completo para empezar',
        weekId: 'w1',
        weekNumber: 1,
        dayId: 'd1',
        dayNumber: today.weekday,
        dayName: 'Pierna y empuje',
        dayStatus: ProgressStatus.pending,
        scheduledDate: today,
        estimatedMinutes: 45,
      ),
      week: TrainingWeek(
        days: [
          for (var i = 0; i < 7; i++)
            TrainingWeekDay(
              date: monday.add(Duration(days: i)),
              today: i == today.weekday - 1,
              state: i == today.weekday - 1
                  ? TrainingDayState.planned
                  : i == 0
                  ? TrainingDayState.done
                  : TrainingDayState.free,
              sessionId: i == 0 && today.weekday != 1 ? 's1' : null,
            ),
        ],
        done: 1,
        total: 2,
      ),
      routines: const [
        RoutineSummary(
          id: 'r1',
          ownerId: 'u1',
          name: 'Cuerpo completo para empezar',
          visibility: vis.Visibility.private,
          status: RoutineStatus.active,
          durationWeeks: 8,
          exerciseCount: 6,
          totalDays: 24,
          completedDays: 1,
        ),
      ],
    );

    testWidgets('hoy toca, atajos, semana y rutinas en ese orden', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(state);
      final semantics = tester.ensureSemantics();
      await pump(tester);

      expect(find.text('Pierna y empuje'), findsOneWidget);
      expect(find.text('≈ 45 min'), findsOneWidget);
      for (final label in [
        'Sesión libre',
        'Plantillas',
        'Ejercicios',
        'Historial',
        'Más',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      expect(find.text('Esta semana'), findsOneWidget);
      expect(find.text('1 de 2 entrenos'), findsOneWidget);
      expect(find.text('Nueva rutina'), findsOneWidget);
      // Hoy se lee como tal, con lo que toca.
      expect(
        find.bySemanticsLabel(RegExp(r', Hoy: toca entrenar$')),
        findsOneWidget,
      );
      // El orden de la maqueta: hoy toca encima de los atajos y de la semana.
      final top = tester.getTopLeft(find.text('Pierna y empuje')).dy;
      final quick = tester.getTopLeft(find.bySemanticsLabel('Plantillas')).dy;
      final week = tester.getTopLeft(find.text('Esta semana')).dy;
      expect(top < quick && quick < week, isTrue);
      semantics.dispose();
    });

    testWidgets('el lector puede activar los atajos y los días', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(state);
      final semantics = tester.ensureSemantics();
      await pump(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Plantillas')),
        isSemantics(
          label: 'Plantillas',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(RegExp(r', Hoy: toca entrenar$')),
        ),
        isSemantics(
          isButton: true,
          hasTapAction: true,
          onTapHint: 'Ver rutina',
        ),
      );
      semantics.dispose();
    });

    testWidgets('«Más» abre lo que no está en la fila', (tester) async {
      when(() => bloc.state).thenReturn(state);
      await pump(tester);
      await tester.tap(find.bySemanticsLabel('Más'));
      await tester.pumpAndSettle();
      expect(find.text('Plan semanal'), findsOneWidget);
      expect(find.text('Comunidad'), findsOneWidget);
      expect(find.text('Entrenar con amigos'), findsOneWidget);
    });

    testWidgets('táctil, etiquetas, contraste y texto al 200 %', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(state);
      final semantics = tester.ensureSemantics();
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await pump(tester, theme: theme);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(const _ContrastWithoutQuickActions()));
      }
      await pump(tester, textScale: 2);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  });

  group('«¿Qué tal estás hoy?» con caras (ADR 0055)', () {
    setUp(() {
      getIt
        ..unregister<QuickCheckInBloc>()
        ..registerFactory<QuickCheckInBloc>(
          () => QuickCheckInBloc(
            getAdaptation: _NotYetToday(),
            submit: _NoSubmit(),
            watchDataChanges: _NoDataChanges(),
          ),
        );
    });

    testWidgets('una cara contesta la energía y abre las otras dos', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      await tester.pump();
      expect(find.byType(AppSegmentedChoice<int>), findsNothing);

      await tester.tap(find.byTooltip('¿Cómo va tu energía? Baja'));
      await tester.pump();

      expect(find.byType(AppSegmentedChoice<int>), findsNWidgets(3));
      // Ya abiertas, las caras se van: no hay dos sitios para contestar.
      expect(find.byTooltip('¿Cómo va tu energía? Baja'), findsNothing);
      semantics.dispose();
    });

    testWidgets('las caras: táctil, etiquetas, contraste y texto al 200 %', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await pump(tester, theme: theme);
        await tester.pump();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(const _ContrastWithoutQuickActions()));
      }
      await pump(tester, textScale: 2);
      await tester.pump();
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  });
}
