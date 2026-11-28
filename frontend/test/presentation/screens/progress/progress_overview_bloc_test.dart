import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_due_study_materials_use_case.dart';
import 'package:synaptixfit/domain/use_cases/home/get_home_dashboard_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/get_progress_overview_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/pause_streak_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/resume_streak_use_case.dart';
import 'package:synaptixfit/presentation/screens/progress/overview/bloc/progress_overview_bloc.dart';

import '../../../progress_fixtures.dart';
import '../data_changes_fake.dart';
import '../academic/academic_fixtures.dart';
import '../home/home_fixtures.dart';

class _MockGetOverview extends Mock
    implements GetProgressOverviewUseCaseContract {}

class _MockGetToday extends Mock implements GetHomeDashboardUseCaseContract {}

class _MockGetDue extends Mock implements GetDueStudyMaterialsUseCaseContract {}

class _MockPause extends Mock implements PauseStreakUseCaseContract {}

class _MockResume extends Mock implements ResumeStreakUseCaseContract {}

void main() {
  late _MockGetOverview getOverview;
  late FakeDataChanges changes;
  late _MockGetToday getToday;
  late _MockGetDue getDue;
  late _MockPause pause;
  late _MockResume resume;

  setUp(() {
    getOverview = _MockGetOverview();
    changes = FakeDataChanges();
    getToday = _MockGetToday();
    getDue = _MockGetDue();
    pause = _MockPause();
    resume = _MockResume();
    // Sin resumen de hoy, «Tu equilibrio» dice el error y deja reintentar.
    when(
      () => getToday(),
    ).thenAnswer((_) async => const Failure(AppError.network()));
  });

  tearDown(() => changes.close());

  ProgressOverviewBloc build() => ProgressOverviewBloc(
    getOverview: getOverview,
    getToday: getToday,
    getDueMaterials: getDue,
    watchChanges: changes.useCase,
    pauseStreak: pause,
    resumeStreak: resume,
  );

  group('pausar racha (ADR 0042)', () {
    final paused = testOverview.streak.copyWith(
      pausedUntil: DateTime(2026, 11, 21),
      canPause: false,
    );

    blocTest<ProgressOverviewBloc, ProgressOverviewState>(
      'pausar pinta la racha del servidor y avisa una vez',
      setUp: () => when(() => pause()).thenAnswer((_) async => Success(paused)),
      build: build,
      seed: () => ProgressOverviewState.loaded(testOverview),
      act: (bloc) => bloc.add(const ProgressOverviewEvent.streakPaused()),
      expect: () => [
        ProgressOverviewState.loaded(testOverview, updatingStreak: true),
        ProgressOverviewState.loaded(
          testOverview.copyWith(streak: paused),
          streakJustPaused: paused,
        ),
      ],
    );

    blocTest<ProgressOverviewBloc, ProgressOverviewState>(
      'sin días de pausa se dice el error y la racha no cambia',
      setUp: () => when(() => pause()).thenAnswer(
        (_) async =>
            const Failure(AppError.business('STREAK_PAUSE_LIMIT_REACHED')),
      ),
      build: build,
      seed: () => ProgressOverviewState.loaded(testOverview),
      act: (bloc) => bloc.add(const ProgressOverviewEvent.streakPaused()),
      expect: () => [
        ProgressOverviewState.loaded(testOverview, updatingStreak: true),
        ProgressOverviewState.loaded(
          testOverview,
          streakError: const AppError.business('STREAK_PAUSE_LIMIT_REACHED'),
        ),
      ],
    );

    blocTest<ProgressOverviewBloc, ProgressOverviewState>(
      'reanudar no vuelve a avisar de la pausa',
      setUp: () => when(
        () => resume(),
      ).thenAnswer((_) async => Success(testOverview.streak)),
      build: build,
      seed: () =>
          ProgressOverviewState.loaded(testOverview.copyWith(streak: paused)),
      act: (bloc) => bloc.add(const ProgressOverviewEvent.streakResumed()),
      expect: () => [
        ProgressOverviewState.loaded(
          testOverview.copyWith(streak: paused),
          updatingStreak: true,
        ),
        ProgressOverviewState.loaded(testOverview),
      ],
    );
  });

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    'al entrar no pide el resumen de Inicio (la lectura más cara, ADR 0066)',
    setUp: () =>
        when(() => getOverview()).thenAnswer((_) async => Success(testOverview)),
    build: build,
    act: (bloc) => bloc.add(const ProgressOverviewEvent.started()),
    expect: () => [
      const ProgressOverviewState.loading(),
      ProgressOverviewState.loaded(testOverview),
    ],
    verify: (_) => verifyNever(() => getToday()),
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    '«Tu equilibrio» se lee al desplegar «Ver más cifras» y luego en cada '
    'recarga',
    setUp: () {
      when(() => getOverview()).thenAnswer((_) async => Success(testOverview));
      when(
        () => getToday(),
      ).thenAnswer((_) async => Success(homeDashboardFixture));
    },
    build: build,
    seed: () => ProgressOverviewState.loaded(testOverview),
    act: (bloc) async {
      bloc.add(const ProgressOverviewEvent.balanceRequested());
      await pump();
      bloc.add(const ProgressOverviewEvent.refreshed());
      await pump();
    },
    expect: () => [
      ProgressOverviewState.loaded(testOverview, loadingToday: true),
      ProgressOverviewState.loaded(testOverview, today: homeDashboardFixture),
      ProgressOverviewState.loaded(
        testOverview,
        today: homeDashboardFixture,
        refreshing: true,
      ),
      ProgressOverviewState.loaded(testOverview, today: homeDashboardFixture),
    ],
    verify: (_) => verify(() => getToday()).called(2),
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    'si «Tu equilibrio» falla al desplegarlo, guarda el error',
    build: build,
    seed: () => ProgressOverviewState.loaded(testOverview),
    act: (bloc) => bloc.add(const ProgressOverviewEvent.balanceRequested()),
    expect: () => [
      ProgressOverviewState.loaded(testOverview, loadingToday: true),
      ProgressOverviewState.loaded(
        testOverview,
        todayError: const AppError.network(),
      ),
    ],
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    'emite failure si la carga falla',
    setUp: () => when(
      () => getOverview(),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    act: (bloc) => bloc.add(const ProgressOverviewEvent.started()),
    expect: () => const [
      ProgressOverviewState.loading(),
      ProgressOverviewState.failure(AppError.network()),
    ],
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    'una recarga fallida conserva los datos y expone el error',
    setUp: () => when(
      () => getOverview(),
    ).thenAnswer((_) async => const Failure(AppError.server())),
    build: build,
    seed: () => ProgressOverviewState.loaded(testOverview),
    act: (bloc) => bloc.add(const ProgressOverviewEvent.refreshed()),
    expect: () => [
      ProgressOverviewState.loaded(testOverview, refreshing: true),
      ProgressOverviewState.loaded(
        testOverview,
        refreshError: const AppError.server(),
      ),
    ],
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    'un cambio social lo refresca en silencio',
    setUp: () => when(
      () => getOverview(),
    ).thenAnswer((_) async => Success(testOverview)),
    build: build,
    act: (bloc) async {
      bloc.add(const ProgressOverviewEvent.started());
      await pump();
      changes.emit({DataTopic.social});
      await pump();
    },
    expect: () => [
      const ProgressOverviewState.loading(),
      ProgressOverviewState.loaded(testOverview),
      ProgressOverviewState.loaded(testOverview, refreshing: true),
      ProgressOverviewState.loaded(testOverview),
    ],
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    'un cambio académico lo refresca («Tu estudio»); uno de retos no',
    setUp: () => when(
      () => getOverview(),
    ).thenAnswer((_) async => Success(testOverview)),
    build: build,
    act: (bloc) async {
      bloc.add(const ProgressOverviewEvent.started());
      await pump();
      changes.emit({DataTopic.academic});
      await pump();
      changes.emit({DataTopic.challenges});
      await pump();
    },
    verify: (_) => verify(() => getOverview()).called(2),
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    '«Ver N repasos pendientes» trae la cola para abrirla en un toque',
    setUp: () => when(
      () => getDue(),
    ).thenAnswer((_) async => Success([material, material.copyWith(id: 'm2')])),
    build: build,
    seed: () => ProgressOverviewState.loaded(testOverview),
    act: (bloc) => bloc.add(const ProgressOverviewEvent.reviewRequested()),
    expect: () => [
      ProgressOverviewState.loaded(testOverview, openingReview: true),
      ProgressOverviewState.loaded(testOverview, reviewQueue: ['m1', 'm2']),
    ],
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    'si no se puede leer la cola, lo dice y luego lo olvida',
    setUp: () => when(
      () => getDue(),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    seed: () => ProgressOverviewState.loaded(testOverview),
    act: (bloc) async {
      bloc.add(const ProgressOverviewEvent.reviewRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ProgressOverviewEvent.reviewHandled());
    },
    expect: () => [
      ProgressOverviewState.loaded(testOverview, openingReview: true),
      ProgressOverviewState.loaded(
        testOverview,
        reviewError: const AppError.network(),
      ),
      ProgressOverviewState.loaded(testOverview),
    ],
  );
}
