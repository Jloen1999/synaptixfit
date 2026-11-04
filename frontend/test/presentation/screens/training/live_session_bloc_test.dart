import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/models/training/session_history.dart';
import 'package:synaptixfit/domain/models/training/exercise.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/session.dart';
import 'package:synaptixfit/domain/use_cases/training/load_pending_sets_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/save_pending_sets_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_last_performance_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_bookends_use_case.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/cancel_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/delete_set_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/finish_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/record_set_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/pause_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/resume_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_clock_intro_hidden_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/hide_session_clock_intro_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/live_session/bloc/live_session_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/training_effect.dart';
import 'package:synaptixfit/domain/models/training/session_adaptation.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_adaptation_use_case.dart';
import 'package:synaptixfit/domain/models/training/load_suggestion.dart';
import 'package:synaptixfit/domain/models/training/set_fields.dart';
import 'package:synaptixfit/domain/use_cases/training/get_load_suggestions_use_case.dart';

import 'training_fixtures.dart';
import 'live_session_draft_fakes.dart';

class _MockGetSession extends Mock implements GetSessionUseCaseContract {}

class _MockPause extends Mock implements PauseSessionUseCaseContract {}

class _MockResume extends Mock implements ResumeSessionUseCaseContract {}

class _MockIntroHidden extends Mock
    implements GetSessionClockIntroHiddenUseCaseContract {}

class _MockHideIntro extends Mock
    implements HideSessionClockIntroUseCaseContract {}

class _MockGetLoads extends Mock implements GetLoadSuggestionsUseCaseContract {}

class _MockLoadPending extends Mock implements LoadPendingSetsUseCaseContract {}

class _MockSavePending extends Mock implements SavePendingSetsUseCaseContract {}

class _MockGetRoutine extends Mock implements GetRoutineUseCaseContract {}

class _MockRecordSet extends Mock implements RecordSetUseCaseContract {}

class _MockDeleteSet extends Mock implements DeleteSetUseCaseContract {}

class _MockFinish extends Mock implements FinishSessionUseCaseContract {}

class _MockCancel extends Mock implements CancelSessionUseCaseContract {}

class _MockGetAccount extends Mock implements GetAccountUseCaseContract {}

class _MockGetLast extends Mock implements GetLastPerformanceUseCaseContract {}

class _MockGetBookends extends Mock
    implements GetSessionBookendsUseCaseContract {}

class _MockGetAdaptation extends Mock
    implements GetSessionAdaptationUseCaseContract {}

void main() {
  late DraftStore drafts;
  late _MockGetSession getSession;
  late _MockGetRoutine getRoutine;
  late _MockRecordSet recordSet;
  late _MockDeleteSet deleteSet;
  late _MockFinish finish;
  late _MockCancel cancel;
  late _MockGetAccount getAccount;
  late _MockGetLast getLast;
  late _MockGetBookends getBookends;
  late _MockGetAdaptation getAdaptation;
  late _MockGetLoads getLoads;
  late _MockLoadPending loadPending;
  late _MockSavePending savePending;
  late _MockIntroHidden introHidden;

  final startedAt = DateTime(2026, 10, 18, 10);
  final now = startedAt.add(const Duration(minutes: 5));
  final routine = TrainingFixtures.routine();
  final exercises = routine.weeks.first.days.first.exercises;

  setUpAll(() {
    registerFallbackValue(const SetRecord(setNumber: 1));
    registerFallbackValue(const <SetRecord>[]);
  });

  setUp(() {
    drafts = DraftStore();
    getSession = _MockGetSession();
    getRoutine = _MockGetRoutine();
    recordSet = _MockRecordSet();
    deleteSet = _MockDeleteSet();
    finish = _MockFinish();
    cancel = _MockCancel();
    getAccount = _MockGetAccount();
    getLast = _MockGetLast();
    getBookends = _MockGetBookends();
    getAdaptation = _MockGetAdaptation();
    getLoads = _MockGetLoads();
    when(() => getLoads(any())).thenAnswer((_) async => const Success([]));
    loadPending = _MockLoadPending();
    savePending = _MockSavePending();
    // Sin series pendientes guardadas en el teléfono salvo en su test.
    when(() => loadPending(any())).thenAnswer((_) async => const Success([]));
    introHidden = _MockIntroHidden();
    // En estas pruebas no se explica el cronómetro (lo cubre live_session_timers_test).
    when(() => introHidden()).thenAnswer((_) async => const Success(true));
    when(
      () => savePending(any(), any()),
    ).thenAnswer((_) async => const Success(unit));
    // Sin motivos: la sesión sale como está planificada salvo en su test.
    when(
      () => getAdaptation(any()),
    ).thenAnswer((_) async => const Success(SessionAdaptation()));
    // Las ayudas (la última vez, calentamiento) llegan vacías salvo en su test.
    when(() => getLast()).thenAnswer((_) async => const Success([]));
    when(
      () => getBookends(any()),
    ).thenAnswer((_) async => const Success(SessionBookends()));
  });

  LiveSessionBloc build({DateTime Function()? clock}) => LiveSessionBloc(
    getSession: getSession,
    getRoutine: getRoutine,
    recordSet: recordSet,
    deleteSet: deleteSet,
    finish: finish,
    cancel: cancel,
    getAccount: getAccount,
    getLastPerformance: getLast,
    getBookends: getBookends,
    getAdaptation: getAdaptation,
    getLoadSuggestions: getLoads,
    loadPending: loadPending,
    savePending: savePending,
    pauseSession: _MockPause(),
    resumeSession: _MockResume(),
    getClockIntroHidden: introHidden,
    hideClockIntro: _MockHideIntro(),
    loadDraft: FakeLoadDraft(drafts),
    saveDraft: FakeSaveDraft(drafts),
    clock: clock ?? () => now,
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
    startedAt: startedAt,
    countedUntil: now,
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

  group('propuesta de carga', () {
    const load = LoadSuggestion(
      plannedExerciseId: 'p1',
      metric: LoadMetric.weight,
      previous: 40,
      suggested: 42,
      changePercent: 5,
      lastRpe: 6,
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'tras cargar, guarda la propuesta de cada ejercicio del día',
      setUp: () {
        when(() => getSession('s1')).thenAnswer(
          (_) async => Success(TrainingFixtures.session(startedAt: startedAt)),
        );
        when(() => getRoutine(any())).thenAnswer((_) async => Success(routine));
        when(() => getLoads('s1')).thenAnswer(
          (_) async => const Success([
            load,
            // De un ejercicio que ya no está en el día: se ignora.
            LoadSuggestion(
              plannedExerciseId: 'otro',
              metric: LoadMetric.reps,
              previous: 10,
              suggested: 11,
              lastRpe: 6,
            ),
          ]),
        );
      },
      build: build,
      act: (bloc) => bloc.add(const LiveSessionEvent.started('s1')),
      skip: 2,
      expect: () => [
        isA<LiveSessionState>().having((s) => s.loadSuggestions, 'propuestas', {
          'p1': load,
        }),
      ],
    );

    test(
      'aceptarla rellena las series que faltan; deshacerla vuelve a lo de antes',
      () {
        final base = ready().copyWith(loadSuggestions: {'p1': load});
        final e = exercises.first;
        expect(base.proposedValue(e, 2, SetField.weight), isNot(42));
        final accepted = base.copyWith(acceptedLoad: {'p1'});
        expect(accepted.proposedValue(e, 2, SetField.weight), 42);
        // Solo cambia la cifra propuesta (el peso); las repeticiones siguen.
        expect(accepted.proposedValue(e, 2, SetField.reps), 10);
      },
    );

    test('cada serie toma la cifra que reparte el servidor', () {
      final e = exercises.first;
      final s = ready().copyWith(
        loadSuggestions: {
          'p1': load.copyWith(perSet: const [21, 31.5, 42]),
        },
        acceptedLoad: {'p1'},
      );
      expect(s.proposedValue(e, 1, SetField.weight), 21);
      expect(s.proposedValue(e, 2, SetField.weight), 31.5);
      expect(s.proposedValue(e, 3, SetField.weight), 42);
    });

    blocTest<LiveSessionBloc, LiveSessionState>(
      'aceptar y deshacer solo cambia qué ejercicios la usan',
      build: build,
      seed: () => ready().copyWith(loadSuggestions: {'p1': load}),
      act: (bloc) => bloc
        ..add(
          const LiveSessionEvent.loadSuggestionToggled('p1', accepted: true),
        )
        ..add(
          const LiveSessionEvent.loadSuggestionToggled('p2', accepted: true),
        )
        ..add(
          const LiveSessionEvent.loadSuggestionToggled('p1', accepted: false),
        ),
      expect: () => [
        isA<LiveSessionState>().having((s) => s.acceptedLoad, 'usa', {'p1'}),
        isA<LiveSessionState>().having(
          (s) => s.acceptedLoad,
          'usa',
          <String>{},
        ),
      ],
    );
  });

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
    expect: () => [
      const LiveSessionState(sessionId: 's1'),
      ready().copyWith(
        plannedSetsById: {for (final e in exercises) e.id: e.parameters.sets},
      ),
    ],
  );

  blocTest<LiveSessionBloc, LiveSessionState>(
    '«Hacerla completa» vuelve a las series planificadas',
    setUp: () {
      when(() => getSession('s1')).thenAnswer(
        (_) async => Success(TrainingFixtures.session(startedAt: startedAt)),
      );
      when(() => getRoutine('r1')).thenAnswer((_) async => Success(routine));
      when(() => getAdaptation('s1')).thenAnswer(
        (_) async => Success(
          SessionAdaptation(
            volumeFactor: 0.7,
            reasons: const [SessionAdaptationReason.examSoon],
            sets: {for (final e in exercises) e.id: 1},
          ),
        ),
      );
    },
    build: build,
    act: (bloc) async {
      bloc.add(const LiveSessionEvent.started('s1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const LiveSessionEvent.adaptationDeclined());
    },
    verify: (bloc) {
      expect(bloc.state.adaptation.adapted, isFalse);
      expect(
        bloc.state.exercises.map((e) => e.parameters.sets),
        exercises.map((e) => e.parameters.sets),
      );
    },
  );

  blocTest<LiveSessionBloc, LiveSessionState>(
    'con examen cerca aplica las series adaptadas por el servidor',
    setUp: () {
      when(() => getSession('s1')).thenAnswer(
        (_) async => Success(TrainingFixtures.session(startedAt: startedAt)),
      );
      when(() => getRoutine('r1')).thenAnswer((_) async => Success(routine));
      when(() => getAdaptation('s1')).thenAnswer(
        (_) async => Success(
          SessionAdaptation(
            volumeFactor: 0.7,
            reasons: const [SessionAdaptationReason.examSoon],
            sets: {for (final e in exercises) e.id: 1},
          ),
        ),
      );
    },
    build: build,
    act: (bloc) => bloc.add(const LiveSessionEvent.started('s1')),
    verify: (bloc) {
      expect(bloc.state.adaptation.adapted, isTrue);
      expect(bloc.state.exercises.every((e) => e.parameters.sets == 1), isTrue);
    },
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

  SessionSet done(String exercise, int n) => SessionSet(
    id: '$exercise-$n',
    plannedExerciseId: exercise,
    setNumber: n,
    repsDone: 10,
    completed: true,
  );

  group('reloj', () {
    late DateTime current;
    Duration secs(int n) => Duration(seconds: n);

    blocTest<LiveSessionBloc, LiveSessionState>(
      'cronómetro, ejercicio activo y descanso salen del reloj, no de sumar tics',
      setUp: () => current = now,
      build: () => build(clock: () => current),
      seed: () => ready().copyWith(
        restEndsAt: now.add(secs(2)),
        restRemaining: 2,
        restTotal: 60,
      ),
      act: (bloc) async {
        current = now.add(secs(1));
        bloc.add(const LiveSessionEvent.ticked());
        await Future<void>.delayed(Duration.zero);
        current = now.add(secs(2));
        bloc.add(const LiveSessionEvent.ticked());
      },
      expect: () => [
        ready(elapsed: 301, seconds: {'p1': 1}).copyWith(
          countedUntil: now.add(secs(1)),
          restEndsAt: now.add(secs(2)),
          restRemaining: 1,
          restTotal: 60,
        ),
        // El descanso llega a cero solo: la pantalla avisa (restFinishedCount sube).
        ready(elapsed: 302, seconds: {'p1': 2}).copyWith(
          countedUntil: now.add(secs(2)),
          restTotal: 60,
          restFinishedCount: 1,
        ),
      ],
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'un tic que llega tarde no pierde tiempo: se cuenta lo que marca el reloj',
      setUp: () => current = now,
      build: () => build(clock: () => current),
      seed: () => ready().copyWith(
        restEndsAt: now.add(secs(30)),
        restRemaining: 30,
        restTotal: 30,
      ),
      act: (bloc) {
        current = now.add(const Duration(milliseconds: 3500));
        bloc.add(const LiveSessionEvent.ticked());
      },
      expect: () => [
        ready(elapsed: 303, seconds: {'p1': 3}).copyWith(
          // Los 0,5 s sobrantes se suman en el siguiente tic.
          countedUntil: now.add(secs(3)),
          restEndsAt: now.add(secs(30)),
          restRemaining: 27,
          restTotal: 30,
        ),
      ],
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'al volver a primer plano recalcula todo y avisa del descanso acabado',
      setUp: () => current = now,
      build: () => build(clock: () => current),
      seed: () => ready().copyWith(
        restEndsAt: now.add(secs(60)),
        restRemaining: 60,
        restTotal: 60,
      ),
      act: (bloc) {
        // La pantalla estuvo apagada minuto y medio: no llegó ningún tic.
        current = now.add(secs(90));
        bloc.add(const LiveSessionEvent.resumed());
      },
      expect: () => [
        ready(elapsed: 390, seconds: {'p1': 90}).copyWith(
          countedUntil: now.add(secs(90)),
          restTotal: 60,
          restFinishedCount: 1,
        ),
      ],
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'añadir tiempo al descanso mueve su final',
      setUp: () => current = now,
      build: () => build(clock: () => current),
      seed: () => ready().copyWith(
        restEndsAt: now.add(secs(10)),
        restRemaining: 10,
        restTotal: 60,
      ),
      act: (bloc) => bloc.add(const LiveSessionEvent.restAdjusted(15)),
      expect: () => [
        ready().copyWith(
          restEndsAt: now.add(secs(25)),
          restRemaining: 25,
          restTotal: 60,
        ),
      ],
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'saltar el descanso lo quita sin avisar',
      build: build,
      seed: () => ready().copyWith(
        restEndsAt: now.add(secs(10)),
        restRemaining: 10,
        restTotal: 60,
      ),
      act: (bloc) => bloc.add(const LiveSessionEvent.restSkipped()),
      expect: () => [ready().copyWith(restTotal: 60)],
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'quitar más tiempo del que queda termina el descanso sin avisar',
      build: build,
      seed: () => ready().copyWith(
        restEndsAt: now.add(secs(10)),
        restRemaining: 10,
        restTotal: 60,
      ),
      act: (bloc) => bloc.add(const LiveSessionEvent.restAdjusted(-15)),
      expect: () => [ready().copyWith(restTotal: 60)],
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'el descanso cuenta desde el toque, aunque el servidor tarde en responder',
      setUp: () {
        current = now;
        when(() => recordSet('s1', any())).thenAnswer((_) async {
          current = now.add(secs(5));
          return Success(TrainingFixtures.session(startedAt: startedAt));
        });
      },
      build: () => build(clock: () => current),
      seed: ready,
      act: (bloc) => bloc.add(
        const LiveSessionEvent.setRecorded(
          SetRecord(plannedExerciseId: 'p2', setNumber: 1, repsDone: 10),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.restEndsAt, now.add(secs(60)));
        expect(bloc.state.restRemaining, 55);
        expect(bloc.state.restTotal, 60);
      },
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'al volver a primer plano intenta subir enseguida las series pendientes',
      setUp: () {
        current = now;
        when(() => recordSet('s1', any())).thenAnswer(
          (_) async => Success(TrainingFixtures.session(startedAt: startedAt)),
        );
      },
      build: () => build(clock: () => current),
      seed: () => ready().copyWith(
        pendingSets: const [SetRecord(plannedExerciseId: 'p1', setNumber: 1)],
      ),
      act: (bloc) {
        current = now.add(secs(3));
        bloc.add(const LiveSessionEvent.resumed());
      },
      verify: (bloc) {
        verify(() => recordSet('s1', any())).called(1);
        expect(bloc.state.pendingSets, isEmpty);
      },
    );
  });

  test('upNext es el ejercicio activo con series por hacer o el siguiente', () {
    expect(ready(active: 'p2').upNext?.id, 'p2');
    final p1Done = TrainingFixtures.session(
      startedAt: startedAt,
      sets: [
        for (var n = 1; n <= 3; n++)
          SessionSet(
            id: 'p1-$n',
            plannedExerciseId: 'p1',
            setNumber: n,
            repsDone: 10,
            completed: true,
          ),
      ],
    );
    final state = ready(session: p1Done);
    expect(state.upNext?.id, 'p2');
    expect(state.nextSetOf(exercises.first), isNull);
    expect(state.nextSetOf(exercises.last), 1);
  });

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
      expect(s.restEndsAt, now.add(const Duration(seconds: 60)));
      expect(s.activeExerciseId, 'p2');
      expect(s.completedSets, 1);
    },
  );

  blocTest<LiveSessionBloc, LiveSessionState>(
    'al completar las series de un ejercicio se pasa solo al siguiente',
    setUp: () => when(() => recordSet('s1', any())).thenAnswer(
      (_) async => Success(
        TrainingFixtures.session(
          startedAt: startedAt,
          sets: [done('p1', 1), done('p1', 2), done('p1', 3)],
        ),
      ),
    ),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(
      const LiveSessionEvent.setRecorded(
        SetRecord(plannedExerciseId: 'p1', setNumber: 3, repsDone: 10),
      ),
    ),
    verify: (bloc) => expect(bloc.state.activeExerciseId, 'p2'),
  );

  blocTest<LiveSessionBloc, LiveSessionState>(
    'con todo hecho ya no cuenta ningún ejercicio',
    setUp: () => when(() => recordSet('s1', any())).thenAnswer(
      (_) async => Success(
        TrainingFixtures.session(
          startedAt: startedAt,
          sets: [
            for (final e in ['p1', 'p2'])
              for (var n = 1; n <= 3; n++) done(e, n),
          ],
        ),
      ),
    ),
    build: build,
    seed: () => ready(active: 'p2'),
    act: (bloc) => bloc.add(
      const LiveSessionEvent.setRecorded(
        SetRecord(plannedExerciseId: 'p2', setNumber: 3, repsDone: 10),
      ),
    ),
    verify: (bloc) => expect(bloc.state.activeExerciseId, isNull),
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

  group('sin conexión', () {
    const record = SetRecord(
      plannedExerciseId: 'p1',
      setNumber: 3,
      repsDone: 10,
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'la serie se guarda en el teléfono, se ve y se sube al volver la red',
      setUp: () {
        when(
          () => recordSet('s1', any()),
        ).thenAnswer((_) async => const Failure(AppError.network()));
      },
      build: build,
      seed: () => ready(),
      act: (bloc) async {
        bloc.add(const LiveSessionEvent.setRecorded(record));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.pendingSets, [record]);
        expect(
          bloc.state.session!.sets.last.id,
          startsWith(LiveSessionBloc.pendingPrefix),
        );
        when(() => recordSet('s1', any())).thenAnswer(
          (_) async => Success(TrainingFixtures.session(startedAt: startedAt)),
        );
        bloc.add(const LiveSessionEvent.pendingRetried());
      },
      verify: (bloc) {
        expect(bloc.state.pendingSets, isEmpty);
        verify(() => savePending('s1', [record])).called(1);
        verify(() => savePending('s1', const [])).called(1);
      },
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'una serie apuntada sin conexión también arranca el descanso',
      setUp: () => when(
        () => recordSet('s1', any()),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      seed: ready,
      act: (bloc) => bloc.add(
        const LiveSessionEvent.setRecorded(
          SetRecord(plannedExerciseId: 'p1', setNumber: 1, repsDone: 10),
        ),
      ),
      verify: (bloc) {
        final s = bloc.state;
        expect(s.pendingSets, hasLength(1));
        expect(s.saving, isFalse);
        expect(s.restRemaining, 90);
        expect(s.restTotal, 90);
        expect(s.restEndsAt, now.add(const Duration(seconds: 90)));
        expect(s.activeExerciseId, 'p1');
      },
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'una serie con repeticiones de menos también descansa y cuenta como hecha',
      setUp: () => when(
        () => recordSet('s1', any()),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      seed: () => ready(
        session: TrainingFixtures.session(
          startedAt: startedAt,
          sets: [done('p1', 1), done('p1', 2)],
        ),
      ),
      act: (bloc) => bloc.add(
        const LiveSessionEvent.setRecorded(
          SetRecord(
            plannedExerciseId: 'p1',
            setNumber: 3,
            repsDone: 6,
            completed: false,
            failedReps: 4,
          ),
        ),
      ),
      verify: (bloc) {
        final s = bloc.state;
        expect(s.pendingSets, hasLength(1));
        expect(s.restRemaining, 90);
        // Las tres series de p1 están apuntadas: se pasa a p2.
        expect(s.loggedSetsOf(exercises.first), 3);
        expect(s.loggedSets, 3);
        expect(s.activeExerciseId, 'p2');
        expect(s.upNext?.id, 'p2');
      },
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'si el servidor está caído la serie sigue en la cola',
      setUp: () => when(
        () => recordSet('s1', any()),
      ).thenAnswer((_) async => const Failure(AppError.server())),
      build: build,
      seed: () => ready().copyWith(pendingSets: const [record]),
      act: (bloc) => bloc.add(const LiveSessionEvent.pendingRetried()),
      verify: (bloc) => expect(bloc.state.pendingSets, [record]),
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'una serie que el servidor rechaza se descarta y se avisa',
      setUp: () => when(
        () => recordSet('s1', any()),
      ).thenAnswer((_) async => const Failure(AppError.validation())),
      build: build,
      seed: () => ready().copyWith(pendingSets: const [record]),
      act: (bloc) => bloc.add(const LiveSessionEvent.pendingRetried()),
      expect: () => [
        isA<LiveSessionState>().having((s) => s.saving, 'saving', isTrue),
        isA<LiveSessionState>().having(
          (s) => s.effect,
          'effect',
          const TrainingEffect.message(TrainingMessage.pendingSetDiscarded),
        ),
        isA<LiveSessionState>().having((s) => s.effect, 'effect', isNull),
        isA<LiveSessionState>()
            .having((s) => s.pendingSets, 'pendingSets', isEmpty)
            .having((s) => s.saving, 'saving', isFalse),
      ],
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'una serie apuntada mientras se guarda otra espera en la cola',
      build: build,
      seed: () => ready().copyWith(saving: true),
      act: (bloc) => bloc.add(const LiveSessionEvent.setRecorded(record)),
      verify: (bloc) {
        expect(bloc.state.pendingSets, [record]);
        // La otra operación sigue en curso: no se apaga su indicador.
        expect(bloc.state.saving, isTrue);
        verifyNever(() => recordSet(any(), any()));
      },
    );

    blocTest<LiveSessionBloc, LiveSessionState>(
      'sin subir las pendientes no se puede terminar',
      setUp: () => when(
        () => recordSet('s1', any()),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      seed: () => ready().copyWith(pendingSets: const [record]),
      act: (bloc) => bloc.add(const LiveSessionEvent.finishRequested(6)),
      verify: (bloc) {
        expect(bloc.state.pendingSets, [record]);
        verifyNever(
          () => finish(
            any(),
            durationSeconds: any(named: 'durationSeconds'),
            rpe: any(named: 'rpe'),
            realDurations: any(named: 'realDurations'),
          ),
        );
      },
    );
  });
}
