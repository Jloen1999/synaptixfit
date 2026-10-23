import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/models/training/session_history.dart';
import 'package:synaptixfit/domain/models/training/exercise.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/session.dart';
import 'package:synaptixfit/domain/use_cases/training/get_last_performance_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_bookends_use_case.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/cancel_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/delete_set_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/finish_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/record_set_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/live_session/bloc/live_session_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/training_effect.dart';

import 'training_fixtures.dart';

class _MockGetSession extends Mock implements GetSessionUseCaseContract {}

class _MockGetRoutine extends Mock implements GetRoutineUseCaseContract {}

class _MockRecordSet extends Mock implements RecordSetUseCaseContract {}

class _MockDeleteSet extends Mock implements DeleteSetUseCaseContract {}

class _MockFinish extends Mock implements FinishSessionUseCaseContract {}

class _MockCancel extends Mock implements CancelSessionUseCaseContract {}

class _MockGetAccount extends Mock implements GetAccountUseCaseContract {}

class _MockGetLast extends Mock implements GetLastPerformanceUseCaseContract {}

class _MockGetBookends extends Mock
    implements GetSessionBookendsUseCaseContract {}

void main() {
  late _MockGetSession getSession;
  late _MockGetRoutine getRoutine;
  late _MockRecordSet recordSet;
  late _MockDeleteSet deleteSet;
  late _MockFinish finish;
  late _MockCancel cancel;
  late _MockGetAccount getAccount;
  late _MockGetLast getLast;
  late _MockGetBookends getBookends;

  final startedAt = DateTime(2026, 10, 18, 10);
  final now = startedAt.add(const Duration(minutes: 5));
  final routine = TrainingFixtures.routine();
  final exercises = routine.weeks.first.days.first.exercises;

  setUpAll(() => registerFallbackValue(const SetRecord(setNumber: 1)));

  setUp(() {
    getSession = _MockGetSession();
    getRoutine = _MockGetRoutine();
    recordSet = _MockRecordSet();
    deleteSet = _MockDeleteSet();
    finish = _MockFinish();
    cancel = _MockCancel();
    getAccount = _MockGetAccount();
    getLast = _MockGetLast();
    getBookends = _MockGetBookends();
    // Las ayudas (la última vez, calentamiento) llegan vacías salvo en su test.
    when(() => getLast()).thenAnswer((_) async => const Success([]));
    when(
      () => getBookends(any()),
    ).thenAnswer((_) async => const Success(SessionBookends()));
  });

  LiveSessionBloc build() => LiveSessionBloc(
    getSession: getSession,
    getRoutine: getRoutine,
    recordSet: recordSet,
    deleteSet: deleteSet,
    finish: finish,
    cancel: cancel,
    getAccount: getAccount,
    getLastPerformance: getLast,
    getBookends: getBookends,
    clock: () => now,
  );

  LiveSessionState ready({
    TrainingSession? session,
    int elapsed = 300,
    String? active = 'p1',
    Map<String, int> seconds = const {},
  }) => LiveSessionState(
    status: LiveStatus.ready,
    sessionId: 's1',
    session: session ?? TrainingFixtures.session(startedAt: startedAt),
    exercises: exercises,
    routineName: 'Fuerza',
    dayNumber: 1,
    elapsedSeconds: elapsed,
    activeExerciseId: active,
    exerciseSeconds: seconds,
  );

  blocTest<LiveSessionBloc, LiveSessionState>(
    'tras cargar, añade lo que hizo la última vez en cada ejercicio',
    setUp: () {
      when(() => getSession('s1')).thenAnswer(
        (_) async => Success(TrainingFixtures.session(startedAt: startedAt)),
      );
      when(
        () => getRoutine(any()),
      ).thenAnswer((_) async => Success(TrainingFixtures.routine()));
      when(() => getLast()).thenAnswer(
        (_) async => Success([
          PersonalRecord(
            exerciseId: exercises.first.exerciseId,
            kind: PersonalRecordKind.weight,
            weightKg: 40,
            reps: 8,
            sessionId: 'old',
            achievedAt: DateTime(2026, 10, 1),
          ),
        ]),
      );
    },
    build: build,
    act: (bloc) => bloc.add(const LiveSessionEvent.started('s1')),
    skip: 2,
    expect: () => [
      isA<LiveSessionState>().having(
        (s) => s.lastPerformance[exercises.first.exerciseId]?.weightKg,
        'peso de la última vez',
        40,
      ),
    ],
  );

  blocTest<LiveSessionBloc, LiveSessionState>(
    'al empezar carga la sesión, los ejercicios del día y el cronómetro',
    setUp: () {
      when(() => getSession('s1')).thenAnswer(
        (_) async => Success(TrainingFixtures.session(startedAt: startedAt)),
      );
      when(() => getRoutine('r1')).thenAnswer((_) async => Success(routine));
    },
    build: build,
    act: (bloc) => bloc.add(const LiveSessionEvent.started('s1')),
    expect: () => [const LiveSessionState(sessionId: 's1'), ready()],
  );

  blocTest<LiveSessionBloc, LiveSessionState>(
    'si la sesión no existe muestra el error',
    setUp: () => when(() => getSession('s1')).thenAnswer(
      (_) async => const Failure(AppError.business('SESSION_NOT_FOUND')),
    ),
    build: build,
    act: (bloc) => bloc.add(const LiveSessionEvent.started('s1')),
    expect: () => const [
      LiveSessionState(sessionId: 's1'),
      LiveSessionState(
        sessionId: 's1',
        status: LiveStatus.failure,
        error: AppError.business('SESSION_NOT_FOUND'),
      ),
    ],
  );

  blocTest<LiveSessionBloc, LiveSessionState>(
    'cada segundo suma al total, al ejercicio activo y descuenta el descanso',
    build: build,
    seed: () => ready().copyWith(restRemaining: 2, restTotal: 60),
    act: (bloc) => bloc
      ..add(const LiveSessionEvent.ticked())
      ..add(const LiveSessionEvent.ticked()),
    expect: () => [
      ready(
        elapsed: 301,
        seconds: {'p1': 1},
      ).copyWith(restRemaining: 1, restTotal: 60),
      ready(elapsed: 302, seconds: {'p1': 2}).copyWith(restTotal: 60),
    ],
  );

  blocTest<LiveSessionBloc, LiveSessionState>(
    'registrar una serie completada actualiza la sesión e inicia el descanso',
    setUp: () => when(() => recordSet('s1', any())).thenAnswer(
      (_) async => Success(
        TrainingFixtures.session(
          startedAt: startedAt,
          sets: const [
            SessionSet(
              id: 'set1',
              plannedExerciseId: 'p2',
              setNumber: 1,
              repsDone: 10,
              completed: true,
            ),
          ],
        ),
      ),
    ),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(
      const LiveSessionEvent.setRecorded(
        SetRecord(plannedExerciseId: 'p2', setNumber: 1, repsDone: 10),
      ),
    ),
    verify: (bloc) {
      final s = bloc.state;
      expect(s.saving, isFalse);
      expect(s.session!.sets, hasLength(1));
      expect(s.restRemaining, 60);
      expect(s.activeExerciseId, 'p2');
      expect(s.completedSets, 1);
    },
  );

  blocTest<LiveSessionBloc, LiveSessionState>(
    'finalizar envía duración, RPE y duración real; refresca la cuenta y abre el resumen',
    setUp: () {
      when(
        () => finish(
          's1',
          durationSeconds: any(named: 'durationSeconds'),
          rpe: any(named: 'rpe'),
          realDurations: any(named: 'realDurations'),
          sets: any(named: 'sets'),
        ),
      ).thenAnswer(
        (_) async => Success(
          FinishSessionResult(
            session: TrainingFixtures.session(
              status: SessionStatus.completed,
              startedAt: startedAt,
            ),
            experience: const ExperienceChange(
              level: 3,
              levelXp: 90,
              xpDelta: 50,
            ),
          ),
        ),
      );
      when(
        () => getAccount(),
      ).thenAnswer((_) async => const Success(TrainingFixtures.account));
    },
    build: build,
    seed: () => ready(seconds: {'p1': 120, 'p2': 0}),
    act: (bloc) => bloc.add(const LiveSessionEvent.finishRequested(7)),
    expect: () => [
      isA<LiveSessionState>().having((s) => s.finishing, 'finishing', true),
      isA<LiveSessionState>()
          .having((s) => s.finishing, 'finishing', false)
          .having((s) => s.completed, 'completed', true),
      isA<LiveSessionState>().having(
        (s) => s.effect,
        'effect',
        const TrainingEffect.accountChanged(TrainingFixtures.account),
      ),
      isA<LiveSessionState>().having((s) => s.effect, 'effect', isNull),
      isA<LiveSessionState>().having(
        (s) => s.effect,
        'effect',
        isA<TrainingEffectSessionFinished>(),
      ),
      isA<LiveSessionState>().having((s) => s.effect, 'effect', isNull),
    ],
    verify: (_) => verify(
      () => finish(
        's1',
        durationSeconds: 300,
        rpe: 7,
        realDurations: {'p1': 120},
      ),
    ).called(1),
  );

  blocTest<LiveSessionBloc, LiveSessionState>(
    'si finalizar falla se mantiene la sesión y se avisa',
    setUp: () => when(
      () => finish(
        's1',
        durationSeconds: any(named: 'durationSeconds'),
        rpe: any(named: 'rpe'),
        realDurations: any(named: 'realDurations'),
        sets: any(named: 'sets'),
      ),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(const LiveSessionEvent.finishRequested(5)),
    expect: () => [
      ready().copyWith(finishing: true),
      ready(),
      ready().copyWith(effect: const TrainingEffect.error(AppError.network())),
      ready(),
    ],
    verify: (_) => verifyNever(() => getAccount()),
  );

  blocTest<LiveSessionBloc, LiveSessionState>(
    'abandonar cancela la sesión y cierra la pantalla',
    setUp: () =>
        when(() => cancel('s1')).thenAnswer((_) async => const Success(unit)),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(const LiveSessionEvent.abandonRequested()),
    verify: (bloc) => verify(() => cancel('s1')).called(1),
    expect: () => [
      ready().copyWith(finishing: true),
      ready(),
      ready().copyWith(
        effect: const TrainingEffect.message(TrainingMessage.sessionAbandoned),
      ),
      ready(),
      ready().copyWith(effect: const TrainingEffect.close()),
      ready(),
    ],
  );
}
