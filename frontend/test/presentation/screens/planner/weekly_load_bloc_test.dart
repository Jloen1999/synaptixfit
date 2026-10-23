import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/weekly_planning.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_week_balance_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_weekly_load_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/sync_weekly_load_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/update_weekly_wellbeing_use_case.dart';
import 'package:synaptixfit/presentation/screens/planner/weekly_load/bloc/weekly_load_bloc.dart';

import 'planner_fixtures.dart';

class _Balance extends Mock implements GetWeekBalanceUseCaseContract {}

class _Load extends Mock implements GetWeeklyLoadUseCaseContract {}

class _Wellbeing extends Mock implements UpdateWeeklyWellbeingUseCaseContract {}

class _Sync extends Mock implements SyncWeeklyLoadUseCaseContract {}

class _Account extends Mock implements GetAccountUseCaseContract {}

void main() {
  setUpAll(registerPlannerFallbacks);

  late _Balance getBalance;
  late _Load getLoad;
  late _Wellbeing updateWellbeing;
  late _Sync syncLoad;
  late _Account getAccount;

  final load = WeeklyLoad(
    weekStart: testMonday,
    plannedHours: 12,
    actualHours: 4,
    exams: 1,
    deliveries: 0,
    stressLevel: 5,
    sleepHours: 7,
  );

  WeeklyLoadBloc build() => WeeklyLoadBloc(
    getBalance: getBalance,
    getLoad: getLoad,
    updateWellbeing: updateWellbeing,
    syncLoad: syncLoad,
    getAccount: getAccount,
  );

  WeeklyLoadState ready() => WeeklyLoadState(
    weekStart: testMonday,
    status: WeeklyLoadStatus.ready,
    balance: testBalance,
    load: load,
  );

  setUp(() {
    getBalance = _Balance();
    getLoad = _Load();
    updateWellbeing = _Wellbeing();
    syncLoad = _Sync();
    getAccount = _Account();
    when(() => getBalance(any())).thenAnswer((_) async => Success(testBalance));
    when(() => getLoad(any())).thenAnswer((_) async => Success(load));
    when(
      () => getAccount(),
    ).thenAnswer((_) async => const Success(testAccount));
  });

  blocTest<WeeklyLoadBloc, WeeklyLoadState>(
    'carga balance y carga semanal',
    build: build,
    act: (bloc) => bloc.add(WeeklyLoadEvent.started(testMonday)),
    expect: () => [
      isA<WeeklyLoadState>().having(
        (s) => s.status,
        'status',
        WeeklyLoadStatus.loading,
      ),
      ready(),
    ],
  );

  blocTest<WeeklyLoadBloc, WeeklyLoadState>(
    'muestra el error si falla la carga',
    setUp: () => when(
      () => getLoad(any()),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    act: (bloc) => bloc.add(WeeklyLoadEvent.started(testMonday)),
    skip: 1,
    expect: () => [
      isA<WeeklyLoadState>()
          .having((s) => s.status, 'status', WeeklyLoadStatus.failure)
          .having((s) => s.error, 'error', const AppError.network()),
    ],
  );

  blocTest<WeeklyLoadBloc, WeeklyLoadState>(
    'guarda estrés, sueño y notas',
    setUp: () =>
        when(
          () => updateWellbeing(
            testMonday,
            stressLevel: 8,
            sleepHours: 6.5,
            notes: 'Exámenes',
          ),
        ).thenAnswer(
          (_) async => Success(
            load.copyWith(stressLevel: 8, sleepHours: 6.5, notes: 'Exámenes'),
          ),
        ),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(
      const WeeklyLoadEvent.wellbeingSaved(
        stressLevel: 8,
        sleepHours: 6.5,
        notes: 'Exámenes',
      ),
    ),
    skip: 1,
    expect: () => [
      isA<WeeklyLoadState>()
          .having((s) => s.load?.stressLevel, 'stress', 8)
          .having((s) => s.saving, 'saving', isFalse)
          .having((s) => s.notice, 'notice', const WeeklyLoadNotice.saved()),
    ],
  );

  blocTest<WeeklyLoadBloc, WeeklyLoadState>(
    'sincronizar con XP refresca la cuenta',
    setUp: () => when(() => syncLoad(testMonday)).thenAnswer(
      (_) async => Success(WeeklyLoadSync(load: load, xpAwarded: 50)),
    ),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(const WeeklyLoadEvent.syncRequested()),
    skip: 1,
    expect: () => [
      isA<WeeklyLoadState>()
          .having((s) => s.syncing, 'syncing', isFalse)
          .having(
            (s) => s.notice,
            'notice',
            const WeeklyLoadNotice.synced(xpAwarded: 50, account: testAccount),
          ),
    ],
  );
}
