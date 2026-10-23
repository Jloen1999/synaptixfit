import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/recommendation.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/domain/models/training/training_page.dart';
import 'package:synaptixfit/domain/use_cases/training/apply_recommendation_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/discard_recommendation_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_my_routines_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_pending_day_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_recommendations_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_today_check_in_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/start_session_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/training_effect.dart';
import 'package:synaptixfit/presentation/screens/training/training_home/bloc/training_home_bloc.dart';

import '../data_changes_fake.dart';
import 'training_fixtures.dart';

class _MockPending extends Mock implements GetPendingDayUseCaseContract {}

class _MockRoutines extends Mock implements GetMyRoutinesUseCaseContract {}

class _MockCheckIn extends Mock implements GetTodayCheckInUseCaseContract {}

class _MockRecs extends Mock implements GetRecommendationsUseCaseContract {}

class _MockApply extends Mock implements ApplyRecommendationUseCaseContract {}

class _MockDiscard extends Mock
    implements DiscardRecommendationUseCaseContract {}

class _MockStart extends Mock implements StartSessionUseCaseContract {}

void main() {
  late _MockPending pending;
  late _MockRoutines routines;
  late _MockCheckIn checkIn;
  late _MockRecs recs;
  late _MockApply apply;
  late _MockDiscard discard;
  late _MockStart start;
  late FakeDataChanges changes;

  const pendingDay = PendingDay(
    routineId: 'r1',
    routineName: 'Fuerza',
    weekId: 'w1',
    weekNumber: 1,
    dayId: 'd1',
    dayNumber: 1,
    dayStatus: ProgressStatus.pending,
  );
  const summary = RoutineSummary(
    id: 'r1',
    ownerId: 'u1',
    name: 'Fuerza',
    visibility: Visibility.private,
    status: RoutineStatus.active,
    durationWeeks: 4,
    exerciseCount: 12,
    totalDays: 12,
    completedDays: 3,
  );
  const rec = Recommendation(
    id: 'rec1',
    type: RecommendationType.progression,
    title: 'Sube peso',
    applied: false,
  );

  setUp(() {
    pending = _MockPending();
    routines = _MockRoutines();
    checkIn = _MockCheckIn();
    recs = _MockRecs();
    apply = _MockApply();
    discard = _MockDiscard();
    start = _MockStart();
    changes = FakeDataChanges();
    when(() => pending()).thenAnswer((_) async => const Success(pendingDay));
    when(() => routines(size: any(named: 'size'))).thenAnswer(
      (_) async => const Success(
        TrainingPage(items: [summary], page: 0, totalPages: 1, totalItems: 1),
      ),
    );
    when(() => checkIn()).thenAnswer((_) async => const Success(null));
    when(() => recs(applied: false)).thenAnswer(
      (_) async => const Success(
        TrainingPage(items: [rec], page: 0, totalPages: 1, totalItems: 1),
      ),
    );
  });

  TrainingHomeBloc build() => TrainingHomeBloc(
    getPendingDay: pending,
    getMyRoutines: routines,
    getTodayCheckIn: checkIn,
    getRecommendations: recs,
    applyRecommendation: apply,
    discardRecommendation: discard,
    startSession: start,
    watchChanges: changes.useCase,
  );

  const ready = TrainingHomeState(
    status: HomeStatus.ready,
    pendingDay: pendingDay,
    routines: [summary],
    recommendations: [rec],
  );

  blocTest<TrainingHomeBloc, TrainingHomeState>(
    'carga día pendiente, rutinas, check-in y sugerencias',
    build: build,
    act: (bloc) => bloc.add(const TrainingHomeEvent.started()),
    expect: () => const [TrainingHomeState(), ready],
  );

  blocTest<TrainingHomeBloc, TrainingHomeState>(
    'si fallan las rutinas muestra el error',
    setUp: () => when(
      () => routines(size: any(named: 'size')),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    act: (bloc) => bloc.add(const TrainingHomeEvent.started()),
    expect: () => const [
      TrainingHomeState(),
      TrainingHomeState(status: HomeStatus.failure, error: AppError.network()),
    ],
  );

  blocTest<TrainingHomeBloc, TrainingHomeState>(
    'descartar una sugerencia la quita de la lista',
    setUp: () => when(
      () => discard('rec1'),
    ).thenAnswer((_) async => const Success(unit)),
    build: build,
    seed: () => ready,
    act: (bloc) =>
        bloc.add(const TrainingHomeEvent.recommendationDiscarded('rec1')),
    expect: () => [
      ready.copyWith(busyIds: {'rec1'}),
      ready.copyWith(recommendations: []),
      ready.copyWith(
        recommendations: [],
        effect: const TrainingEffect.message(
          TrainingMessage.recommendationDiscarded,
        ),
      ),
      ready.copyWith(recommendations: []),
    ],
  );

  blocTest<TrainingHomeBloc, TrainingHomeState>(
    'empezar el día pendiente abre la sesión en vivo',
    setUp: () => when(
      () => start(routineId: 'r1', dayId: 'd1'),
    ).thenAnswer((_) async => Success(TrainingFixtures.session())),
    build: build,
    seed: () => ready,
    act: (bloc) => bloc.add(
      const TrainingHomeEvent.sessionStarted(routineId: 'r1', dayId: 'd1'),
    ),
    expect: () => [
      ready.copyWith(startingSession: true),
      ready,
      ready.copyWith(effect: const TrainingEffect.openSession('s1')),
      ready,
    ],
  );

  tearDown(() => changes.close());

  blocTest<TrainingHomeBloc, TrainingHomeState>(
    'un cambio del planificador la refresca en silencio',
    build: build,
    act: (bloc) async {
      bloc.add(const TrainingHomeEvent.started());
      await pump();
      changes.emit({DataTopic.planner});
      await pump();
    },
    verify: (_) => verify(() => pending()).called(2),
  );

  blocTest<TrainingHomeBloc, TrainingHomeState>(
    'un cambio de retos no la refresca',
    build: build,
    act: (bloc) async {
      bloc.add(const TrainingHomeEvent.started());
      await pump();
      changes.emit({DataTopic.challenges});
      await pump();
    },
    verify: (_) => verify(() => pending()).called(1),
  );
}
