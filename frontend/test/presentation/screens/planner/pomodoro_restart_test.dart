import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synaptixfit/data/local_data_source/active_focus_timer_storage.dart';
import 'package:synaptixfit/data/repository/active_focus_timer_repository.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/focus.dart';
import 'package:synaptixfit/domain/models/reminders/ongoing_timer.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/clear_active_focus_timer_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_focus_plan_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_focus_stats_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/load_active_focus_timer_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/record_focus_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/save_active_focus_timer_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/update_ongoing_timer_use_case.dart';
import 'package:synaptixfit/presentation/screens/planner/pomodoro/bloc/pomodoro_bloc.dart';

import 'planner_fixtures.dart';

/// Preferencias del teléfono en memoria: sobreviven a «cerrar la app» porque
/// el mapa es el mismo para los dos procesos simulados.
class _MemoryPreferences extends Fake implements SharedPreferencesAsync {
  _MemoryPreferences(this._values);

  final Map<String, String> _values;

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}

class _Record extends Mock implements RecordFocusSessionUseCaseContract {}

class _Stats extends Mock implements GetFocusStatsUseCaseContract {}

class _Account extends Mock implements GetAccountUseCaseContract {}

class _Plan extends Mock implements GetFocusPlanUseCaseContract {}

class _Ongoing extends Mock implements UpdateOngoingTimerUseCaseContract {}

const _texts = PomodoroAlertTexts(
  focusEndTitle: 'Bloque terminado',
  focusEndBody: 'Toca descansar',
  breakEndTitle: 'Pausa terminada',
  breakEndBody: 'Vuelve',
  channelName: 'Pomodoro',
  focusRunningTitle: 'Concentración',
  breakRunningTitle: 'Pausa',
  pausedTitle: 'En pausa',
  endsAtBody: _endsAt,
  remainingBody: _remaining,
  ongoingChannelName: 'Pomodoro en marcha',
);

String _endsAt(DateTime at) => 'Termina';
String _remaining(String clock) => 'Quedan $clock';

/// «Atrás hasta salir» o «quitar de recientes» matan el proceso: el bloc nuevo
/// solo tiene lo que quedó en el teléfono. La fase debe seguir donde iba.
void main() {
  setUpAll(
    () => registerFallbackValue(
      const OngoingTimer(title: '', body: '', channelName: ''),
    ),
  );

  late Map<String, String> phone;
  late DateTime clock;
  late _Account account;
  late _Ongoing ongoing;

  setUp(() {
    phone = {};
    clock = testNow;
    account = _Account();
    ongoing = _Ongoing();
    when(() => ongoing(any())).thenAnswer((_) async => const Success(unit));
    when(() => account()).thenAnswer((_) async => const Success(testAccount));
  });

  /// Un «proceso» de la app: bloc con el almacenamiento real sobre [phone].
  PomodoroBloc process({String? sessionAccountId}) {
    final repository = ActiveFocusTimerRepository(
      ActiveFocusTimerStorage(_MemoryPreferences(phone)),
    );
    final stats = _Stats();
    when(() => stats()).thenAnswer(
      (_) async =>
          const Success(FocusStats(today: FocusTotals(), week: FocusTotals())),
    );
    final plan = _Plan();
    when(
      () => plan(),
    ).thenAnswer((_) async => const Failure(AppError.network()));
    return PomodoroBloc(
      recordSession: _Record(),
      getStats: stats,
      getAccount: account,
      getPlan: plan,
      updateOngoing: ongoing,
      loadTimer: LoadActiveFocusTimerUseCase(repository),
      saveTimer: SaveActiveFocusTimerUseCase(repository),
      clearTimer: ClearActiveFocusTimerUseCase(repository),
      config: const PomodoroConfig(focusMinutes: 25),
      now: () => clock,
      ticker: () => const Stream<void>.empty(),
    );
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<PomodoroBloc> startInFirstProcess() async {
    final first = process();
    first.add(const PomodoroEvent.started(alertTexts: _texts));
    await settle();
    await settle();
    first.add(const PomodoroEvent.startPressed());
    await settle();
    expect(first.state.status, PomodoroStatus.running);
    expect(phone, isNotEmpty, reason: 'la fase se guarda al empezar');
    return first;
  }

  test('tras cerrar la app, la fase sigue con el tiempo correcto', () async {
    await startInFirstProcess();
    clock = clock.add(const Duration(minutes: 10));

    final second = process();
    second.add(const PomodoroEvent.restored(alertTexts: _texts));
    await settle();
    await settle();

    expect(second.state.status, PomodoroStatus.running);
    expect(second.state.remainingSeconds, 15 * 60);
    expect(phone, isNotEmpty);
    await second.close();
  });

  test(
    'si al volver no se puede leer la cuenta (sin red o renovando la sesión), '
    'la fase no se pierde',
    () async {
      await startInFirstProcess();
      clock = clock.add(const Duration(minutes: 10));
      // Solo cuenta lo que hace el proceso nuevo.
      clearInteractions(ongoing);
      when(
        () => account(),
      ).thenAnswer((_) async => const Failure(AppError.network()));

      final second = process();
      second.add(const PomodoroEvent.restored(alertTexts: _texts));
      await settle();
      await settle();

      expect(second.state.status, PomodoroStatus.running);
      expect(phone, isNotEmpty, reason: 'no se borra la fase guardada');
      verifyNever(() => ongoing(null));
      await second.close();
    },
  );

  test('la fase de otra cuenta del mismo teléfono se descarta', () async {
    await startInFirstProcess();
    final second = process();
    second.add(
      const PomodoroEvent.restored(alertTexts: _texts, accountId: 'otra'),
    );
    await settle();
    await settle();

    expect(second.state.status, PomodoroStatus.idle);
    expect(phone, isEmpty);
    await second.close();
  });
}
