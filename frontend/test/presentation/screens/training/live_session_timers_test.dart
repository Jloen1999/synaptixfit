import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/session.dart';
import 'package:synaptixfit/domain/models/training/session_adaptation.dart';
import 'package:synaptixfit/domain/models/training/exercise.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/cancel_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/delete_set_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/finish_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_last_performance_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_load_suggestions_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_adaptation_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_bookends_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/load_pending_sets_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/pause_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/record_set_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/resume_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/save_pending_sets_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_clock_intro_hidden_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/hide_session_clock_intro_use_case.dart';
import 'package:synaptixfit/domain/models/training/live_session_draft.dart';
import 'package:synaptixfit/presentation/screens/training/live_session/bloc/live_session_bloc.dart';

import 'training_fixtures.dart';
import 'live_session_draft_fakes.dart';

class _GetSession extends Mock implements GetSessionUseCaseContract {}

class _GetRoutine extends Mock implements GetRoutineUseCaseContract {}

class _RecordSet extends Mock implements RecordSetUseCaseContract {}

class _DeleteSet extends Mock implements DeleteSetUseCaseContract {}

class _Finish extends Mock implements FinishSessionUseCaseContract {}

class _Cancel extends Mock implements CancelSessionUseCaseContract {}

class _GetAccount extends Mock implements GetAccountUseCaseContract {}

class _GetLast extends Mock implements GetLastPerformanceUseCaseContract {}

class _GetBookends extends Mock implements GetSessionBookendsUseCaseContract {}

class _GetAdaptation extends Mock
    implements GetSessionAdaptationUseCaseContract {}

class _GetLoads extends Mock implements GetLoadSuggestionsUseCaseContract {}

class _LoadPending extends Mock implements LoadPendingSetsUseCaseContract {}

class _SavePending extends Mock implements SavePendingSetsUseCaseContract {}

class _Pause extends Mock implements PauseSessionUseCaseContract {}

class _Resume extends Mock implements ResumeSessionUseCaseContract {}

class _IntroHidden extends Mock
    implements GetSessionClockIntroHiddenUseCaseContract {}

class _HideIntro extends Mock implements HideSessionClockIntroUseCaseContract {}

/// Cronómetro por serie y pausas (ADR 0030) con escenarios reales: el
/// cronómetro ayuda pero nunca obliga.
void main() {
  // Lo que guarda el teléfono: sobrevive a crear otro bloc (reabrir la app).
  late DraftStore drafts;
  late _RecordSet recordSet;
  late _GetSession getSession;
  late _GetRoutine getRoutine;
  late _Pause pause;
  late _Resume resume;
  late _IntroHidden introHidden;
  late _HideIntro hideIntro;
  late _Finish finish;
  late DateTime current;

  final startedAt = DateTime(2026, 11, 2, 18);
  final routine = TrainingFixtures.routine();
  final exercises = routine.weeks.first.days.first.exercises;

  setUpAll(() => registerFallbackValue(const SetRecord(setNumber: 1)));

  setUp(() {
    drafts = DraftStore();
    current = startedAt.add(const Duration(minutes: 5));
    recordSet = _RecordSet();
    getSession = _GetSession();
    getRoutine = _GetRoutine();
    pause = _Pause();
    resume = _Resume();
    introHidden = _IntroHidden();
    hideIntro = _HideIntro();
    finish = _Finish();
    when(() => recordSet(any(), any())).thenAnswer(
      (_) async => Success(TrainingFixtures.session(startedAt: startedAt)),
    );
    when(() => pause(any())).thenAnswer(
      (_) async => Success(
        TrainingFixtures.session(
          startedAt: startedAt,
        ).copyWith(pausedAt: current),
      ),
    );
    when(
      () => resume(any(), resumedAt: any(named: 'resumedAt')),
    ).thenAnswer(
      (_) async => Success(TrainingFixtures.session(startedAt: startedAt)),
    );
  });

  LiveSessionBloc build() {
    final getLast = _GetLast();
    final getBookends = _GetBookends();
    final getAdaptation = _GetAdaptation();
    final getLoads = _GetLoads();
    final loadPending = _LoadPending();
    final savePending = _SavePending();
    when(() => getLast()).thenAnswer((_) async => const Success([]));
    when(
      () => getBookends(any()),
    ).thenAnswer((_) async => const Success(SessionBookends()));
    when(
      () => getAdaptation(any()),
    ).thenAnswer((_) async => const Success(SessionAdaptation()));
    when(() => getLoads(any())).thenAnswer((_) async => const Success([]));
    when(() => loadPending(any())).thenAnswer((_) async => const Success([]));
    when(
      () => savePending(any(), any()),
    ).thenAnswer((_) async => const Success(unit));
    return LiveSessionBloc(
      getSession: getSession,
      getRoutine: getRoutine,
      recordSet: recordSet,
      deleteSet: _DeleteSet(),
      finish: finish,
      cancel: _Cancel(),
      getAccount: _GetAccount(),
      getLastPerformance: getLast,
      getBookends: getBookends,
      getAdaptation: getAdaptation,
      getLoadSuggestions: getLoads,
      loadPending: loadPending,
      savePending: savePending,
      pauseSession: pause,
      resumeSession: resume,
      getClockIntroHidden: introHidden,
      hideClockIntro: hideIntro,
      loadDraft: FakeLoadDraft(drafts),
      saveDraft: FakeSaveDraft(drafts),
      clock: () => current,
    );
  }

  LiveSessionState ready() => LiveSessionState(
    status: LiveStatus.ready,
    sessionId: 's1',
    session: TrainingFixtures.session(startedAt: startedAt),
    exercises: exercises,
    elapsedSeconds: 300,
    startedAt: startedAt,
    countedUntil: current,
    activeExerciseId: 'p1',
  );

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  SetRecord recorded() =>
      verify(() => recordSet('s1', captureAny())).captured.last as SetRecord;

  test(
    'olvidé empezar el cronómetro: la serie se marca igual, sin tiempo',
    () async {
      final bloc = build()..emit(ready());
      bloc.add(
        const LiveSessionEvent.setRecorded(
          SetRecord(plannedExerciseId: 'p1', setNumber: 1, repsDone: 10),
        ),
      );
      await settle();
      expect(recorded().activeSeconds, isNull);
      await bloc.close();
    },
  );

  test('con el cronómetro de la serie se guarda lo que tardó', () async {
    final bloc = build()..emit(ready());
    bloc.add(const LiveSessionEvent.setTimerStarted('p1', 1));
    await settle();
    current = current.add(const Duration(seconds: 48));
    bloc.add(const LiveSessionEvent.ticked());
    await settle();
    expect(bloc.state.timerSeconds, 48);
    bloc.add(
      const LiveSessionEvent.setRecorded(
        SetRecord(plannedExerciseId: 'p1', setNumber: 1, repsDone: 10),
      ),
    );
    await settle();
    expect(recorded().activeSeconds, 48);
    expect(bloc.state.timerSet, isNull);
    await bloc.close();
  });

  test(
    'una llamada larga en mitad de la serie no cuenta ni en la serie ni en la sesión',
    () async {
      final bloc = build()..emit(ready());
      bloc.add(const LiveSessionEvent.setTimerStarted('p1', 1));
      await settle();
      current = current.add(const Duration(seconds: 20));
      bloc.add(const LiveSessionEvent.pauseRequested());
      await settle();
      expect(bloc.state.paused, isTrue);
      verify(() => pause('s1')).called(1);

      // Diez minutos al teléfono.
      current = current.add(const Duration(minutes: 10));
      bloc.add(const LiveSessionEvent.ticked());
      await settle();
      expect(bloc.state.elapsedSeconds, 300 + 20);
      expect(bloc.state.timerSeconds, 20);

      bloc.add(const LiveSessionEvent.resumeRequested());
      await settle();
      verify(
        () => resume('s1', resumedAt: any(named: 'resumedAt')),
      ).called(1);
      current = current.add(const Duration(seconds: 10));
      bloc.add(const LiveSessionEvent.ticked());
      await settle();
      expect(bloc.state.paused, isFalse);
      expect(bloc.state.elapsedSeconds, 300 + 30);

      bloc.add(
        const LiveSessionEvent.setRecorded(
          SetRecord(plannedExerciseId: 'p1', setNumber: 1, repsDone: 10),
        ),
      );
      await settle();
      expect(recorded().activeSeconds, 30);
      await bloc.close();
    },
  );

  test(
    'máquina ocupada: se hace antes otro ejercicio sin perder el cronómetro',
    () async {
      final bloc = build()..emit(ready());
      bloc.add(const LiveSessionEvent.setTimerStarted('p1', 1));
      await settle();
      bloc
        ..add(const LiveSessionEvent.exerciseSelected('p2'))
        ..add(
          const LiveSessionEvent.setRecorded(
            SetRecord(plannedExerciseId: 'p2', setNumber: 1, repsDone: 12),
          ),
        );
      await settle();
      expect(recorded().activeSeconds, isNull);
      // El cronómetro de la serie 1 de p1 sigue ahí para cuando vuelva.
      expect(bloc.state.timerSet, 1);
      expect(bloc.state.timerExerciseId, 'p1');
      await bloc.close();
    },
  );

  test(
    'una serie extra (fuera del plan) también se puede cronometrar',
    () async {
      final bloc = build()..emit(ready());
      bloc.add(const LiveSessionEvent.setTimerStarted('p1', 4));
      await settle();
      current = current.add(const Duration(seconds: 35));
      bloc.add(
        const LiveSessionEvent.setRecorded(
          SetRecord(plannedExerciseId: 'p1', setNumber: 4, repsDone: 8),
        ),
      );
      await settle();
      final extra = recorded();
      expect(extra.setNumber, 4);
      expect(extra.activeSeconds, 35);
      await bloc.close();
    },
  );

  test('marcar una serie en pausa reanuda la sesión', () async {
    final bloc = build()..emit(ready());
    bloc.add(const LiveSessionEvent.pauseRequested());
    await settle();
    bloc.add(
      const LiveSessionEvent.setRecorded(
        SetRecord(plannedExerciseId: 'p1', setNumber: 1, repsDone: 10),
      ),
    );
    await settle();
    expect(bloc.state.paused, isFalse);
    verify(
        () => resume('s1', resumedAt: any(named: 'resumedAt')),
      ).called(1);
    await bloc.close();
  });

  group('reanudar sin conexión', () {
    test(
      'se reintenta con la hora del toque y no se termina hasta que llega',
      () async {
        final bloc = build()..emit(ready());
        bloc.add(const LiveSessionEvent.pauseRequested());
        await settle();
        current = current.add(const Duration(minutes: 5));
        final resumedAt = current;
        when(
          () => resume(any(), resumedAt: any(named: 'resumedAt')),
        ).thenAnswer((_) async => const Failure(AppError.network()));
        bloc.add(const LiveSessionEvent.resumeRequested());
        await settle();
        expect(bloc.state.paused, isFalse);
        expect(bloc.state.resumePendingAt, resumedAt);

        // Sigue sin conexión al terminar: no se termina (el servidor
        // contaría como pausa lo entrenado después).
        current = current.add(const Duration(minutes: 40));
        bloc.add(const LiveSessionEvent.finishRequested(7));
        await settle();
        verifyNever(
          () => finish(
            any(),
            durationSeconds: any(named: 'durationSeconds'),
            rpe: any(named: 'rpe'),
            realDurations: any(named: 'realDurations'),
          ),
        );

        // Vuelve la cobertura: se manda la hora real de reanudar.
        when(
          () => resume(any(), resumedAt: any(named: 'resumedAt')),
        ).thenAnswer(
          (_) async => Success(TrainingFixtures.session(startedAt: startedAt)),
        );
        bloc.add(const LiveSessionEvent.pendingRetried());
        await settle();
        expect(bloc.state.resumePendingAt, isNull);
        final sent = verify(
          () => resume('s1', resumedAt: captureAny(named: 'resumedAt')),
        ).captured;
        expect(sent.last, resumedAt);
        await bloc.close();
      },
    );
  });

  group('explicación del cronómetro', () {
    setUp(() {
      current = startedAt.add(const Duration(seconds: 20));
      when(() => getSession('s1')).thenAnswer(
        (_) async => Success(TrainingFixtures.session(startedAt: startedAt)),
      );
      when(() => getRoutine(any())).thenAnswer((_) async => Success(routine));
    });

    test(
      'al empezar una sesión se explica que el cronómetro ya corre',
      () async {
        when(() => introHidden()).thenAnswer((_) async => const Success(false));
        when(() => hideIntro()).thenAnswer((_) async => const Success(unit));
        final bloc = build()..add(const LiveSessionEvent.started('s1'));
        await settle();
        await settle();
        expect(bloc.state.explainClock, isTrue);
        bloc.add(const LiveSessionEvent.clockExplained(hideNextTime: true));
        await settle();
        expect(bloc.state.explainClock, isFalse);
        verify(() => hideIntro()).called(1);
        await bloc.close();
      },
    );

    test('si no se puede leer la preferencia, se explica', () async {
      when(
        () => introHidden(),
      ).thenAnswer((_) async => const Failure(AppError.unknown()));
      final bloc = build()..add(const LiveSessionEvent.started('s1'));
      await settle();
      await settle();
      expect(bloc.state.explainClock, isTrue);
      await bloc.close();
    });

    test('con «No volver a explicarlo» ya no se explica', () async {
      when(() => introHidden()).thenAnswer((_) async => const Success(true));
      final bloc = build()..add(const LiveSessionEvent.started('s1'));
      await settle();
      await settle();
      expect(bloc.state.explainClock, isFalse);
      await bloc.close();
    });
  });

  group('Tanda 1: lo que no se pierde y libertad al entrenar', () {
    setUp(() {
      when(() => getSession('s1')).thenAnswer(
        (_) async => Success(TrainingFixtures.session(startedAt: startedAt)),
      );
      when(() => getRoutine(any())).thenAnswer((_) async => Success(routine));
      when(() => introHidden()).thenAnswer((_) async => const Success(true));
    });

    test(
      'cierro la app con la serie cronometrándose: al volver sigue contando',
      () async {
        final first = build()..add(const LiveSessionEvent.started('s1'));
        await settle();
        first.add(const LiveSessionEvent.setTimerStarted('p1', 1));
        await settle();
        await first.close();

        // La app se cierra 40 s y se vuelve a abrir la sesión.
        current = current.add(const Duration(seconds: 40));
        final again = build()..add(const LiveSessionEvent.started('s1'));
        await settle();
        await settle();
        expect(again.state.timerSet, 1);
        expect(again.state.timerExerciseId, 'p1');
        expect(again.state.timerSeconds, 40);
        again.add(
          const LiveSessionEvent.setRecorded(
            SetRecord(plannedExerciseId: 'p1', setNumber: 1, repsDone: 10),
          ),
        );
        await settle();
        expect(recorded().activeSeconds, 40);
        // Ya marcada, no queda nada guardado del cronómetro.
        expect(drafts.drafts['s1']?.timerSet, isNull);
        await again.close();
      },
    );

    test(
      'máquina ocupada: «Usar hoy» cambia el ejercicio solo en esta sesión',
      () async {
        final bloc = build()..add(const LiveSessionEvent.started('s1'));
        await settle();
        await settle();
        bloc.add(
          const LiveSessionEvent.exerciseSwapped(
            'p1',
            ExerciseSwap(exerciseId: 'ex-otro', name: 'Press con mancuernas'),
          ),
        );
        await settle();
        final swapped = bloc.state.exercises.firstWhere((e) => e.id == 'p1');
        expect(swapped.exerciseName, 'Press con mancuernas');
        expect(bloc.state.originals['p1']?.exerciseId, 'ex-p1');

        bloc.add(
          const LiveSessionEvent.setRecorded(
            SetRecord(plannedExerciseId: 'p1', setNumber: 1, repsDone: 10),
          ),
        );
        await settle();
        // La serie se guarda con el ejercicio que se hizo de verdad.
        expect(recorded().exerciseId, 'ex-otro');

        // Reabrir la sesión conserva el cambio de hoy.
        await bloc.close();
        final again = build()..add(const LiveSessionEvent.started('s1'));
        await settle();
        await settle();
        expect(
          again.state.exercises.firstWhere((e) => e.id == 'p1').exerciseId,
          'ex-otro',
        );
        // Y se puede volver al de la rutina.
        again.add(const LiveSessionEvent.exerciseSwapped('p1', null));
        await settle();
        expect(
          again.state.exercises.firstWhere((e) => e.id == 'p1').exerciseId,
          'ex-p1',
        );
        expect(again.state.originals, isEmpty);
        await again.close();
      },
    );

    test(
      'una serie de calentamiento no abre descanso ni cuenta como trabajo',
      () async {
        final bloc = build()..emit(ready());
        bloc.add(
          const LiveSessionEvent.setRecorded(
            SetRecord(
              plannedExerciseId: 'p1',
              setNumber: 1,
              repsDone: 12,
              weightKg: 20,
              warmup: true,
            ),
          ),
        );
        await settle();
        expect(recorded().warmup, isTrue);
        expect(bloc.state.restRemaining, isNull);
        expect(bloc.state.activeExerciseId, 'p1');
        await bloc.close();
      },
    );

    test('sin conexión, el calentamiento pendiente va a su propia lista', () async {
      when(
        () => recordSet(any(), any()),
      ).thenAnswer((_) async => const Failure(AppError.network()));
      final bloc = build()..emit(ready());
      bloc
        ..add(
          const LiveSessionEvent.setRecorded(
            SetRecord(plannedExerciseId: 'p1', setNumber: 1, warmup: true),
          ),
        )
        ..add(
          const LiveSessionEvent.setRecorded(
            SetRecord(plannedExerciseId: 'p1', setNumber: 1, repsDone: 10),
          ),
        );
      await settle();
      await settle();
      expect(bloc.state.session!.warmupSetsFor('p1'), hasLength(1));
      expect(bloc.state.session!.setsFor('p1'), hasLength(1));
      // Borrar el calentamiento pendiente no toca la serie de trabajo.
      final warm = bloc.state.session!.warmupSetsFor('p1').single;
      bloc.add(LiveSessionEvent.setDeleted(warm.id));
      await settle();
      expect(bloc.state.session!.warmupSetsFor('p1'), isEmpty);
      expect(bloc.state.session!.setsFor('p1'), hasLength(1));
      expect(bloc.state.pendingSets.single.warmup, isFalse);
      await bloc.close();
    });

    test('en la sesión libre también se cronometra cada serie', () async {
      final bloc = build()..emit(ready().copyWith(exercises: const []));
      bloc.add(const LiveSessionEvent.setTimerStarted(null, 1));
      await settle();
      current = current.add(const Duration(seconds: 35));
      bloc.add(
        const LiveSessionEvent.setRecorded(SetRecord(setNumber: 1, repsDone: 8)),
      );
      await settle();
      expect(recorded().activeSeconds, 35);
      await bloc.close();
    });
  });
}
