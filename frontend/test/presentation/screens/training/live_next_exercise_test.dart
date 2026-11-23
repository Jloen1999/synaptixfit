import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/social/together.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/domain/models/training/session.dart';
import 'package:synaptixfit/domain/use_cases/social/together/find_workout_together_by_session_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/social/together/live/bloc/workout_together_live_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/live_session/bloc/live_session_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/live_session/page/live_session_page.dart';
import 'package:synaptixfit/presentation/screens/training/widgets/exercise_thumbnail.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/theme/tokens.g.dart';

import 'training_fixtures.dart';

/// Sesión en vivo, tanda 4 (ADR 0062): al acabar un ejercicio y pasar al
/// siguiente, se resalta con texto («Ahora toca»), la tira y la lista se
/// desplazan hasta él (sin animación si se pide reducir el movimiento) y se
/// anuncia al lector una sola vez.
class _MockLiveBloc extends MockBloc<LiveSessionEvent, LiveSessionState>
    implements LiveSessionBloc {}

class _NotTogether implements FindWorkoutTogetherBySessionUseCaseContract {
  @override
  Future<AppResult<WorkoutTogether?>> call(String sessionId) async =>
      const Success(null);
}

/// Diez ejercicios de 3 series sin descanso (así «Ir al siguiente» no
/// compite con la cuenta atrás) salvo que se diga otra cosa.
List<PlannedExercise> _exercises({int rest = 0}) => [
  for (var i = 1; i <= 10; i++)
    TrainingFixtures.planned(
      'p$i',
      order: i - 1,
      rest: rest,
    ).copyWith(exerciseName: i == 2 ? 'Press banca' : 'Ejercicio $i'),
];

SessionSet _done(String exercise, int n) => SessionSet(
  id: '$exercise-$n',
  plannedExerciseId: exercise,
  setNumber: n,
  repsDone: 10,
  completed: true,
);

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  late _MockLiveBloc bloc;

  setUp(() {
    bloc = _MockLiveBloc();
    getIt
      ..registerFactory<LiveSessionBloc>(() => bloc)
      ..registerFactory<WorkoutTogetherLiveBloc>(
        () => WorkoutTogetherLiveBloc(find: _NotTogether()),
      );
  });

  tearDown(() {
    getIt
      ..unregister<LiveSessionBloc>()
      ..unregister<WorkoutTogetherLiveBloc>();
  });

  Future<void> pump(
    WidgetTester tester, {
    double width = 360,
    double height = 800,
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = Size(width, height);
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
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: const LiveSessionPage(sessionId: 's1'),
      ),
    );
    await tester.pump();
  }

  /// Mirando el ejercicio 1 con [doneSets] series hechas.
  LiveSessionState onFirst({int doneSets = 2, int rest = 0}) =>
      LiveSessionState(
        status: LiveStatus.ready,
        sessionId: 's1',
        session: TrainingFixtures.session(
          sets: [for (var n = 1; n <= doneSets; n++) _done('p1', n)],
        ),
        exercises: _exercises(rest: rest),
        dayNumber: 1,
        routineName: 'Fuerza',
        activeExerciseId: 'p1',
      );

  /// [from] tras acabar el ejercicio 1 y pasar a [to].
  LiveSessionState advancedTo(LiveSessionState from, String to, {int? rest}) =>
      from.copyWith(
        session: TrainingFixtures.session(
          sets: [for (var n = 1; n <= 3; n++) _done('p1', n)],
        ),
        activeExerciseId: to,
        advancedCount: from.advancedCount + 1,
        restRemaining: rest,
        restTotal: rest ?? 0,
      );

  List<String> announcements(WidgetTester tester) => [
    for (final a in tester.takeAnnouncements()) a.message,
  ];

  testWidgets('al marcar la última serie, el siguiente se resalta y se anuncia '
      'una vez junto con el descanso', (tester) async {
    final semantics = tester.ensureSemantics();
    final before = onFirst(rest: 90);
    whenListen(
      bloc,
      Stream.value(advancedTo(before, 'p2', rest: 90)),
      initialState: before,
    );
    await pump(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // El que toca lleva «Ahora toca» en texto, no solo el borde de color.
    expect(find.text('Ahora toca'), findsOneWidget);
    expect(find.text('Press banca'), findsWidgets);
    expect(find.text('Ejercicio 2 de 10'), findsOneWidget);

    final spoken = announcements(tester);
    expect(
      spoken.where((m) => m.contains('Siguiente: Press banca')),
      hasLength(1),
    );
    expect(
      spoken,
      contains(
        'Descanso: quedan 90 segundos. Siguiente: Press banca, serie 1 de 3',
      ),
    );
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('«Ir al siguiente» pide pasar y el siguiente se anuncia una '
      'sola vez', (tester) async {
    final semantics = tester.ensureSemantics();
    final finished = onFirst(doneSets: 3);
    whenListen(
      bloc,
      const Stream<LiveSessionState>.empty(),
      initialState: finished,
    );
    await pump(tester);
    // Mirando uno ya hecho: sin «Ahora toca» y con «Ir al siguiente».
    expect(find.text('Ahora toca'), findsNothing);
    await tester.tap(find.text('Ir al siguiente'));
    await tester.pump();
    verify(
      () => bloc.add(const LiveSessionEvent.nextExerciseRequested('p2')),
    ).called(1);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());

    final semantics2 = tester.ensureSemantics();
    whenListen(
      bloc,
      Stream.value(advancedTo(finished, 'p2')),
      initialState: finished,
    );
    await pump(tester);
    await tester.pumpAndSettle();
    expect(announcements(tester), ['Siguiente: Press banca, serie 1 de 3']);
    expect(find.text('Ahora toca'), findsOneWidget);
    semantics2.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('al marcar la última serie, un solo anuncio: la serie, el '
      'descanso y el siguiente', (tester) async {
    final semantics = tester.ensureSemantics();
    final before = onFirst(rest: 90);
    final controller = StreamController<LiveSessionState>();
    whenListen(bloc, controller.stream, initialState: before);
    await pump(tester);
    await tester.tap(find.text('Ya la hice'));
    await tester.pump();
    // Aún sin guardar: no se dice nada.
    expect(announcements(tester), isEmpty);

    controller.add(advancedTo(before, 'p2', rest: 90));
    await tester.pumpAndSettle();
    expect(announcements(tester), [
      'Serie 3 registrada. Descanso: quedan 90 segundos. '
          'Siguiente: Press banca, serie 1 de 3',
    ]);
    await controller.close();
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('en la tira, el que toca lleva ▶ y el lector oye «Ahora toca»', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    whenListen(
      bloc,
      const Stream<LiveSessionState>.empty(),
      initialState: onFirst(),
    );
    await pump(tester);
    expect(
      find.bySemanticsLabel(RegExp(r'^Ejercicio 1 de 10: .*Ahora toca$')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'Ahora toca$')), findsOneWidget);
    // En la tira, un solo ▶: el del que toca.
    expect(
      find.descendant(
        of: find
            .ancestor(
              of: find.byType(ExerciseThumbnail).first,
              matching: find.byType(SingleChildScrollView),
            )
            .first,
        matching: find.byIcon(Icons.play_arrow_rounded),
      ),
      findsOneWidget,
    );
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tocar otro ejercicio de la tira no se anuncia como siguiente', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final before = onFirst();
    whenListen(
      bloc,
      Stream.value(before.copyWith(activeExerciseId: 'p3')),
      initialState: before,
    );
    await pump(tester);
    await tester.pumpAndSettle();
    expect(
      announcements(tester).where((m) => m.contains('Siguiente')),
      isEmpty,
    );
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  /// La tira de ejercicios de la cabecera: la lista horizontal que contiene
  /// la primera miniatura (las demás van en la barra de abajo).
  ScrollPosition stripPosition(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .ancestor(
              of: find.byType(ExerciseThumbnail).first,
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Scrollable && w.axisDirection == AxisDirection.right,
              ),
            )
            .first,
      )
      .position;

  ScrollPosition listPosition(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position;

  testWidgets('la tira se desplaza con animación hasta el siguiente', (
    tester,
  ) async {
    final before = onFirst();
    // Del 1 al 9: fuera de la pantalla en la tira.
    final after = before.copyWith(activeExerciseId: 'p9', advancedCount: 1);
    whenListen(bloc, Stream.value(after), initialState: before);
    await pump(tester);
    // El primer cuadro empieza a moverse; al acabar, el 9 está a la vista.
    await tester.pump();
    expect(stripPosition(tester).pixels, 0);
    await tester.pumpAndSettle();
    expect(stripPosition(tester).pixels, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('con «reducir movimiento», la tira y la lista saltan sin '
      'animación al siguiente', (tester) async {
    final before = onFirst();
    final controller = StreamController<LiveSessionState>();
    whenListen(bloc, controller.stream, initialState: before);
    await pump(tester, height: 600, reduceMotion: true);
    // La persona había bajado por la tabla de series.
    listPosition(tester).jumpTo(listPosition(tester).maxScrollExtent);
    await tester.pump();
    final scrolled = listPosition(tester).pixels;
    expect(scrolled, greaterThan(TokensSpacing.m));

    controller.add(before.copyWith(activeExerciseId: 'p9', advancedCount: 1));
    await tester.pump();
    await tester.pump();
    // Sin pumpAndSettle: ya está, sin animación.
    expect(stripPosition(tester).pixels, greaterThan(0));
    // La lista vuelve arriba lo justo para que se vea el título (debajo de
    // su margen).
    expect(listPosition(tester).pixels, lessThanOrEqualTo(TokensSpacing.m));
    expect(
      tester.getTopLeft(find.text('Ahora toca')).dy,
      greaterThan(tester.getBottomLeft(find.byType(AppBar)).dy),
    );
    await controller.close();
    await tester.pumpWidget(const SizedBox());
  });

  for (final reduceMotion in [false, true]) {
    testWidgets('320 px con texto al 200 %: el siguiente se resalta sin '
        'cortarse (reducir movimiento: $reduceMotion)', (tester) async {
      final semantics = tester.ensureSemantics();
      final before = onFirst(rest: 90);
      whenListen(
        bloc,
        Stream.value(advancedTo(before, 'p2', rest: 90)),
        initialState: before,
      );
      await pump(
        tester,
        width: 320,
        height: 640,
        textScale: 2,
        reduceMotion: reduceMotion,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Ahora toca'), findsOneWidget);
      expect(
        announcements(tester).where((m) => m.contains('Siguiente')),
        hasLength(1),
      );
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  }
}
