import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/calendar_block.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/log_past_activity_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/past_activity/bloc/past_activity_bloc.dart';

class _Log extends Mock implements LogPastActivityUseCaseContract {}

class _GetAccount extends Mock implements GetAccountUseCaseContract {}

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

  PastActivityBloc build() =>
      PastActivityBloc(logPastActivity: log, getAccount: getAccount);

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
