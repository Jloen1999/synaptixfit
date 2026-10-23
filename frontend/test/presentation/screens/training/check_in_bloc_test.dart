import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/training_page.dart';
import 'package:synaptixfit/domain/models/training/wellbeing.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_check_ins_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_today_check_in_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/submit_check_in_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/check_in/bloc/check_in_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/training_effect.dart';

import 'training_fixtures.dart';

class _Today extends Mock implements GetTodayCheckInUseCaseContract {}

class _History extends Mock implements GetCheckInsUseCaseContract {}

class _Submit extends Mock implements SubmitCheckInUseCaseContract {}

class _Account extends Mock implements GetAccountUseCaseContract {}

void main() {
  late _Today today;
  late _History history;
  late _Submit submit;
  late _Account account;

  final checkIn = CheckIn(
    id: 'c1',
    date: DateTime(2026, 10, 18),
    sleepQuality: 4,
    stress: 2,
    energy: 4,
    soreness: 1,
    readyToTrain: true,
    fatigueScore: 20,
    requiresAdaptation: false,
  );

  setUpAll(() => registerFallbackValue(const CheckInInput()));

  setUp(() {
    today = _Today();
    history = _History();
    submit = _Submit();
    account = _Account();
    when(() => history(size: any(named: 'size'))).thenAnswer(
      (_) async => const Success(
        TrainingPage<CheckIn>(items: [], page: 0, totalPages: 0, totalItems: 0),
      ),
    );
  });

  CheckInBloc build() => CheckInBloc(
    getToday: today,
    getHistory: history,
    submit: submit,
    getAccount: account,
  );

  blocTest<CheckInBloc, CheckInState>(
    'sin check-in hoy parte de valores por defecto',
    setUp: () =>
        when(() => today()).thenAnswer((_) async => const Success(null)),
    build: build,
    act: (bloc) => bloc.add(const CheckInEvent.started()),
    expect: () => const [
      CheckInState(),
      CheckInState(status: CheckInStatus.ready),
    ],
  );

  blocTest<CheckInBloc, CheckInState>(
    'el primer check-in del día da experiencia y refresca la cuenta',
    setUp: () {
      when(() => submit(any())).thenAnswer(
        (_) async => Success(
          CheckInResult(checkIn: checkIn, firstOfDay: true, xpAwarded: 20),
        ),
      );
      when(
        () => account(),
      ).thenAnswer((_) async => const Success(TrainingFixtures.account));
    },
    build: build,
    seed: () => const CheckInState(status: CheckInStatus.ready),
    act: (bloc) => bloc
      ..add(
        const CheckInEvent.inputChanged(
          CheckInInput(sleepQuality: 4, stress: 2, energy: 4, soreness: 1),
        ),
      )
      ..add(const CheckInEvent.submitted()),
    verify: (bloc) {
      verify(
        () => submit(
          const CheckInInput(
            sleepQuality: 4,
            stress: 2,
            energy: 4,
            soreness: 1,
          ),
        ),
      ).called(1);
      verify(() => account()).called(1);
      expect(bloc.state.today, checkIn);
      expect(bloc.state.lastResult?.xpAwarded, 20);
      expect(bloc.state.history, [checkIn]);
    },
    expect: () => [
      isA<CheckInState>(),
      isA<CheckInState>().having((s) => s.submitting, 'submitting', true),
      isA<CheckInState>().having((s) => s.today, 'today', checkIn),
      isA<CheckInState>().having(
        (s) => s.effect,
        'effect',
        const TrainingEffect.message(TrainingMessage.checkInSaved),
      ),
      isA<CheckInState>().having((s) => s.effect, 'effect', isNull),
      isA<CheckInState>().having(
        (s) => s.effect,
        'effect',
        const TrainingEffect.accountChanged(TrainingFixtures.account),
      ),
      isA<CheckInState>().having((s) => s.effect, 'effect', isNull),
    ],
  );
}
