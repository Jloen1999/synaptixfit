import 'package:bloc_test/bloc_test.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
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
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/training_home/bloc/training_home_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/training_home/page/training_home_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'training_fixtures.dart';

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
    getIt.registerFactory<TrainingHomeBloc>(() => bloc);
  });

  tearDown(() => getIt.unregister<TrainingHomeBloc>());

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

  testWidgets('la sugerencia se despliega y anuncia su estado', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

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

  testWidgets('«Ver todas» anuncia si la lista está desplegada', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    final seeAll = find.widgetWithText(TextButton, 'Ver todas');
    expect(
      tester.getSemantics(seeAll).flagsCollection.isExpanded,
      Tristate.isFalse,
    );
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
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
      semantics.dispose();
    });

    testWidgets('con el texto al 200 % no se corta ni se solapa', (
      tester,
    ) async {
      await pump(tester, textScale: 2);
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
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        await pump(tester, textScale: 2);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  });
}
