import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/focus.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_focus_plan_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_focus_stats_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/record_focus_session_use_case.dart';
import 'package:synaptixfit/presentation/screens/planner/pomodoro/bloc/pomodoro_bloc.dart';

import 'planner_fixtures.dart';

class _Record extends Mock implements RecordFocusSessionUseCaseContract {}

class _Stats extends Mock implements GetFocusStatsUseCaseContract {}

class _Account extends Mock implements GetAccountUseCaseContract {}

class _Plan extends Mock implements GetFocusPlanUseCaseContract {}

void main() {
  setUpAll(registerPlannerFallbacks);

  late _Record record;
  late _Stats getStats;
  late _Account getAccount;
  late _Plan getPlan;
  late DateTime clock;
  late StreamController<void> ticks;

  const stats = FocusStats(
    today: FocusTotals(focusMinutes: 25, focusCycles: 1, sessions: 1),
    week: FocusTotals(focusMinutes: 100, focusCycles: 4, sessions: 4),
  );

  // Fases cortas para que el test sea legible: 2 / 1 / 3 minutos, largo cada 2.
  const config = PomodoroConfig(
    focusMinutes: 2,
    shortBreakMinutes: 1,
    longBreakMinutes: 3,
    cyclesBeforeLongBreak: 2,
  );

  PomodoroBloc build({PomodoroConfig pomodoro = config}) => PomodoroBloc(
    recordSession: record,
    getStats: getStats,
    getAccount: getAccount,
    getPlan: getPlan,
    config: pomodoro,
    now: () => clock,
    ticker: () => ticks.stream,
  );

  Future<void> tickAfter(PomodoroBloc bloc, Duration elapsed) async {
    clock = clock.add(elapsed);
    ticks.add(null);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    record = _Record();
    getStats = _Stats();
    getAccount = _Account();
    getPlan = _Plan();
    // Por defecto sin recomendación: se quedan las duraciones del test.
    when(
      () => getPlan(),
    ).thenAnswer((_) async => const Failure(AppError.network()));
    clock = testNow;
    ticks = StreamController<void>.broadcast();
    when(() => getStats()).thenAnswer((_) async => const Success(stats));
    when(
      () => record(any()),
    ).thenAnswer((_) async => const Success(FocusSessionResult()));
    when(
      () => getAccount(),
    ).thenAnswer((_) async => const Success(testAccount));
  });

  tearDown(() => ticks.close());

  blocTest<PomodoroBloc, PomodoroState>(
    'carga las estadísticas',
    build: build,
    act: (bloc) => bloc.add(const PomodoroEvent.started()),
    expect: () => [
      isA<PomodoroState>().having((s) => s.statsLoading, 'loading', isTrue),
      isA<PomodoroState>()
          .having((s) => s.statsLoading, 'loading', isFalse)
          .having((s) => s.stats, 'stats', stats),
    ],
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'cuenta atrás con el reloj, pausa y reanuda sin perder tiempo',
    build: build,
    act: (bloc) async {
      bloc.add(const PomodoroEvent.startPressed());
      await Future<void>.delayed(Duration.zero);
      await tickAfter(bloc, const Duration(seconds: 30));
      bloc.add(const PomodoroEvent.pausePressed());
      await Future<void>.delayed(Duration.zero);
      // En pausa el tiempo no corre.
      clock = clock.add(const Duration(minutes: 10));
      bloc.add(const PomodoroEvent.resumePressed());
      await Future<void>.delayed(Duration.zero);
      await tickAfter(bloc, const Duration(seconds: 10));
    },
    expect: () => [
      isA<PomodoroState>().having(
        (s) => s.status,
        'status',
        PomodoroStatus.running,
      ),
      isA<PomodoroState>().having((s) => s.remainingSeconds, 'left', 90),
      isA<PomodoroState>().having(
        (s) => s.status,
        'status',
        PomodoroStatus.paused,
      ),
      isA<PomodoroState>().having(
        (s) => s.status,
        'status',
        PomodoroStatus.running,
      ),
      isA<PomodoroState>().having((s) => s.remainingSeconds, 'left', 80),
    ],
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'al terminar la concentración la registra y pasa al descanso',
    build: build,
    act: (bloc) async {
      bloc.add(const PomodoroEvent.startPressed());
      await Future<void>.delayed(Duration.zero);
      await tickAfter(bloc, const Duration(minutes: 2));
      await Future<void>.delayed(Duration.zero);
    },
    verify: (bloc) {
      expect(bloc.state.phase, FocusPhase.shortBreak);
      expect(bloc.state.status, PomodoroStatus.idle);
      expect(bloc.state.remainingSeconds, 60);
      expect(bloc.state.completedFocusCycles, 1);
      expect(
        bloc.state.notice,
        const PomodoroNotice.phaseFinished(
          finished: FocusPhase.focus,
          next: FocusPhase.shortBreak,
        ),
      );
      verify(
        () => record(
          const FocusSessionRecord(phase: FocusPhase.focus, durationMinutes: 2),
        ),
      ).called(1);
      verify(() => getStats()).called(1);
      // NOT_ELIGIBLE: ni aviso extra ni refresco de cuenta.
      verifyNever(() => getAccount());
    },
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'si el servidor concede XP (AWARDED) la anuncia con la cuenta refrescada',
    setUp: () => when(() => record(any())).thenAnswer(
      (_) async => const Success(
        FocusSessionResult(xpAwarded: 5, xpStatus: FocusXpStatus.awarded),
      ),
    ),
    build: build,
    act: (bloc) async {
      bloc.add(const PomodoroEvent.startPressed());
      await Future<void>.delayed(Duration.zero);
      await tickAfter(bloc, const Duration(minutes: 2));
      await Future<void>.delayed(Duration.zero);
    },
    verify: (bloc) {
      expect(
        bloc.state.notice,
        const PomodoroNotice.xpEarned(xp: 5, account: testAccount),
      );
      verify(() => getAccount()).called(1);
    },
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'si el servidor indica DAILY_CAP_REACHED avisa del tope diario',
    setUp: () => when(() => record(any())).thenAnswer(
      (_) async => const Success(
        FocusSessionResult(xpStatus: FocusXpStatus.dailyCapReached),
      ),
    ),
    build: build,
    act: (bloc) async {
      bloc.add(const PomodoroEvent.startPressed());
      await Future<void>.delayed(Duration.zero);
      await tickAfter(bloc, const Duration(minutes: 2));
      await Future<void>.delayed(Duration.zero);
    },
    verify: (bloc) {
      expect(bloc.state.notice, const PomodoroNotice.dailyXpLimitReached());
      verifyNever(() => getAccount());
    },
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'NOT_ELIGIBLE no añade aviso aunque no haya XP (p. ej. un descanso)',
    build: build,
    seed: () => const PomodoroState(
      phase: FocusPhase.shortBreak,
      totalSeconds: 60,
      remainingSeconds: 60,
    ),
    act: (bloc) async {
      bloc.add(const PomodoroEvent.startPressed());
      await Future<void>.delayed(Duration.zero);
      await tickAfter(bloc, const Duration(minutes: 1));
      await Future<void>.delayed(Duration.zero);
    },
    verify: (bloc) => expect(
      bloc.state.notice,
      const PomodoroNotice.phaseFinished(
        finished: FocusPhase.shortBreak,
        next: FocusPhase.focus,
      ),
    ),
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'tras el número de ciclos configurado toca descanso largo',
    build: build,
    seed: () => const PomodoroState(
      totalSeconds: 120,
      remainingSeconds: 120,
      completedFocusCycles: 1,
    ),
    act: (bloc) async {
      bloc.add(const PomodoroEvent.startPressed());
      await Future<void>.delayed(Duration.zero);
      await tickAfter(bloc, const Duration(minutes: 3));
      await Future<void>.delayed(Duration.zero);
    },
    verify: (bloc) {
      expect(bloc.state.phase, FocusPhase.longBreak);
      expect(bloc.state.remainingSeconds, 180);
    },
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'saltar enseguida no registra; saltar a mitad registra como incompleta',
    build: build,
    act: (bloc) async {
      bloc.add(const PomodoroEvent.skipPressed());
      await Future<void>.delayed(Duration.zero);
      // Ahora en descanso corto (1 min): saltar tras 0 s → sin registro.
      expect(bloc.state.phase, FocusPhase.shortBreak);
      bloc.add(const PomodoroEvent.skipPressed());
      await Future<void>.delayed(Duration.zero);
      // De nuevo concentración (2 min): corre 61 s y se salta.
      bloc.add(const PomodoroEvent.startPressed());
      await Future<void>.delayed(Duration.zero);
      clock = clock.add(const Duration(seconds: 61));
      bloc.add(const PomodoroEvent.skipPressed());
      await Future<void>.delayed(Duration.zero);
    },
    verify: (bloc) {
      expect(bloc.state.phase, FocusPhase.shortBreak);
      expect(bloc.state.completedFocusCycles, 0);
      verify(
        () => record(
          const FocusSessionRecord(
            phase: FocusPhase.focus,
            durationMinutes: 1,
            completed: false,
          ),
        ),
      ).called(1);
    },
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'si falla el registro avisa',
    setUp: () => when(
      () => record(any()),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    act: (bloc) async {
      bloc.add(const PomodoroEvent.startPressed());
      await Future<void>.delayed(Duration.zero);
      await tickAfter(bloc, const Duration(minutes: 2));
      await Future<void>.delayed(Duration.zero);
    },
    verify: (bloc) => expect(
      bloc.state.notice,
      const PomodoroNotice.recordFailed(AppError.network()),
    ),
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'reiniciar vuelve a concentración con el ciclo a cero',
    build: build,
    seed: () => const PomodoroState(
      phase: FocusPhase.shortBreak,
      status: PomodoroStatus.paused,
      totalSeconds: 60,
      remainingSeconds: 20,
      completedFocusCycles: 1,
    ),
    act: (bloc) => bloc.add(const PomodoroEvent.resetPressed()),
    expect: () => [
      const PomodoroState(totalSeconds: 120, remainingSeconds: 120),
    ],
  );

  group('recomendación del servidor', () {
    const plan = FocusPlan(
      focusMinutes: 40,
      shortBreakMinutes: 13,
      longBreakMinutes: 30,
      cyclesBeforeLongBreak: 3,
      limitedByFatigue: true,
      minFocusMinutes: 15,
      maxFocusMinutes: 90,
    );

    setUp(
      () => when(() => getPlan()).thenAnswer((_) async => const Success(plan)),
    );

    blocTest<PomodoroBloc, PomodoroState>(
      'arranca con la duración recomendada y se puede ajustar antes de empezar',
      build: build,
      act: (bloc) async {
        bloc.add(const PomodoroEvent.started());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const PomodoroEvent.focusMinutesChanged(45))
          ..add(const PomodoroEvent.focusMinutesChanged(200));
      },
      verify: (bloc) {
        expect(bloc.state.plan, plan);
        // 200 se recorta al máximo que permite el servidor.
        expect(bloc.config.focusMinutes, 90);
        expect(bloc.state.totalSeconds, 90 * 60);
        expect(bloc.config.shortBreakMinutes, 13);
      },
    );

    blocTest<PomodoroBloc, PomodoroState>(
      'con la sesión en marcha ya no se cambia la duración',
      build: build,
      act: (bloc) async {
        bloc.add(const PomodoroEvent.started());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PomodoroEvent.startPressed());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PomodoroEvent.focusMinutesChanged(60));
      },
      verify: (bloc) => expect(bloc.config.focusMinutes, 40),
    );
  });

  blocTest<PomodoroBloc, PomodoroState>(
    'las fases registradas quedan vinculadas a la asignatura y al bloque',
    build: build,
    act: (bloc) async {
      bloc.add(const PomodoroEvent.started(subjectId: 'sub1', blockId: 'b1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const PomodoroEvent.startPressed());
      await Future<void>.delayed(Duration.zero);
      await tickAfter(bloc, const Duration(minutes: 2));
      await Future<void>.delayed(Duration.zero);
    },
    verify: (_) => verify(
      () => record(
        const FocusSessionRecord(
          phase: FocusPhase.focus,
          durationMinutes: 2,
          subjectId: 'sub1',
          blockId: 'b1',
        ),
      ),
    ).called(1),
  );
}
