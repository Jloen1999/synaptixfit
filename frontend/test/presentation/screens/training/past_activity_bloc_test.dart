import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/calendar_block.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/sport_activity.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/log_past_activity_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_pending_day_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/log_past_session_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/past_activity/bloc/past_activity_bloc.dart';

class _Log extends Mock implements LogPastActivityUseCaseContract {}

class _GetAccount extends Mock implements GetAccountUseCaseContract {}

class _GetPending extends Mock implements GetPendingDayUseCaseContract {}

class _GetRoutine extends Mock implements GetRoutineUseCaseContract {}

class _LogPastSession extends Mock implements LogPastSessionUseCaseContract {}

class _FakeCompletion extends Fake implements BlockCompletion {
  _FakeCompletion(this.xpDelta);

  @override
  final int xpDelta;
}

void main() {
  late _Log log;
  late _GetAccount getAccount;
  final start = DateTime(2026, 10, 30, 18);

  setUp(() {
    log = _Log();
    getAccount = _GetAccount();
  });

  PastActivityBloc build() => PastActivityBloc(
    logPastActivity: log,
    getAccount: getAccount,
    getPendingDay: _GetPending(),
    getRoutine: _GetRoutine(),
    logPastSession: _LogPastSession(),
  );

  blocTest<PastActivityBloc, PastActivityState>(
    'sin XP (tope del día) se guarda igual y no recarga la cuenta',
    setUp: () => when(
      () => log(start: start, minutes: 60, effort: 6, title: 'Fútbol'),
    ).thenAnswer((_) async => Success(_FakeCompletion(0))),
    build: build,
    act: (bloc) => bloc.add(
      PastActivityEvent.submitted(
        start: start,
        minutes: 60,
        effort: 6,
        title: 'Fútbol',
      ),
    ),
    expect: () => const [
      PastActivityState(submitting: true),
      PastActivityState(savedXp: 0),
    ],
    verify: (_) => verifyNever(() => getAccount()),
  );

  // Deportes (ADR 0068): lo elegido en el formulario del deporte viaja tal
  // cual; qué vale en cada deporte lo decide el servidor.
  const padel = SportEntry(
    sport: Sport.padel,
    mode: SportMode.match,
    result: MatchResult.win,
    scoreText: '6-4 6-3',
  );

  blocTest<PastActivityBloc, PastActivityState>(
    'un partido se guarda con su deporte, resultado y marcador',
    setUp: () => when(
      () => log(
        start: start,
        minutes: 90,
        effort: 7,
        title: 'Pádel',
        kind: ActivityKind.match,
        sport: padel,
      ),
    ).thenAnswer((_) async => Success(_FakeCompletion(0))),
    build: build,
    act: (bloc) => bloc.add(
      PastActivityEvent.submitted(
        start: start,
        minutes: 90,
        effort: 7,
        title: 'Pádel',
        kind: ActivityKind.match,
        sport: padel,
      ),
    ),
    expect: () => const [
      PastActivityState(submitting: true),
      PastActivityState(savedXp: 0),
    ],
    verify: (_) => verify(
      () => log(
        start: start,
        minutes: 90,
        effort: 7,
        title: 'Pádel',
        kind: ActivityKind.match,
        sport: padel,
      ),
    ).called(1),
  );

  blocTest<PastActivityBloc, PastActivityState>(
    'natación y «otro deporte» mandan sus metros y su nombre',
    setUp: () => when(
      () => log(
        start: any(named: 'start'),
        minutes: any(named: 'minutes'),
        effort: any(named: 'effort'),
        title: any(named: 'title'),
        kind: any(named: 'kind'),
        distanceMeters: any(named: 'distanceMeters'),
        sport: any(named: 'sport'),
      ),
    ).thenAnswer((_) async => Success(_FakeCompletion(0))),
    build: build,
    act: (bloc) async {
      bloc.add(
        PastActivityEvent.submitted(
          start: start,
          minutes: 40,
          effort: 5,
          title: 'Natación',
          kind: ActivityKind.swim,
          distanceMeters: 1500,
          sport: const SportEntry(sport: Sport.swim),
        ),
      );
      await bloc.stream.firstWhere((s) => s.savedXp != null);
    },
    verify: (_) => verify(
      () => log(
        start: start,
        minutes: 40,
        effort: 5,
        title: 'Natación',
        kind: ActivityKind.swim,
        distanceMeters: 1500,
        sport: const SportEntry(sport: Sport.swim),
      ),
    ).called(1),
  );

  blocTest<PastActivityBloc, PastActivityState>(
    'una actividad de hace más de 7 días da el error del servidor',
    setUp: () =>
        when(
          () => log(
            start: any(named: 'start'),
            minutes: any(named: 'minutes'),
            effort: any(named: 'effort'),
            title: any(named: 'title'),
          ),
        ).thenAnswer(
          (_) async => const Failure(
            AppError.business('PLANNER_PAST_ACTIVITY_OUT_OF_RANGE'),
          ),
        ),
    build: build,
    act: (bloc) => bloc.add(
      PastActivityEvent.submitted(start: start, minutes: 60, effort: 6),
    ),
    expect: () => const [
      PastActivityState(submitting: true),
      PastActivityState(
        error: AppError.business('PLANNER_PAST_ACTIVITY_OUT_OF_RANGE'),
      ),
    ],
  );
}
