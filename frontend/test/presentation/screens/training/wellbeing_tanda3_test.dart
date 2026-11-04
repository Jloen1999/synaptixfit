import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/training/dto/wellbeing_extra_dtos.dart';
import 'package:synaptixfit/domain/enums/reminder_kind.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_composer.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_plan.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/cycle.dart';
import 'package:synaptixfit/domain/models/training/session_adaptation.dart';
import 'package:synaptixfit/domain/models/training/sport_activity.dart';
import 'package:synaptixfit/domain/models/training/today_adaptation.dart';
import 'package:synaptixfit/domain/models/training/training_page.dart';
import 'package:synaptixfit/domain/use_cases/training/change_cycle_tracking_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/delete_cycle_day_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/delete_cycle_history_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_cycle_overview_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_today_adaptation_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/list_cycle_days_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/log_cycle_day_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/submit_quick_check_in_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/cycle/bloc/cycle_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/quick_check_in/bloc/quick_check_in_bloc.dart';

import '../../../domain/reminders/reminder_test_texts.dart';

/// Servidor de mentira del ciclo: guarda lo que se apunta y responde como el
/// backend (apagado por defecto; activar exige consentimiento).
class _FakeCycleServer {
  bool enabled = false;
  final days = <DateTime, CycleDay>{};

  CycleOverview get _overview => CycleOverview(
    enabled: enabled,
    phase: enabled && days.values.any((d) => d.period)
        ? CyclePhase.period
        : null,
  );

  Future<AppResult<CycleOverview>> change({
    bool? enabled,
    bool consent = false,
    bool deleteHistory = false,
  }) async {
    if (enabled == null) return Result.success(_overview);
    if (enabled && !consent) {
      return const Result.failure(AppError.business('CYCLE_CONSENT_REQUIRED'));
    }
    this.enabled = enabled;
    if (!enabled && deleteHistory) days.clear();
    return Result.success(_overview);
  }

  Future<AppResult<CycleOverview>> log(CycleDay day) async {
    days[day.date] = day;
    return Result.success(_overview);
  }
}

class _Get implements GetCycleOverviewUseCaseContract {
  _Get(this.server);
  final _FakeCycleServer server;
  @override
  Future<AppResult<CycleOverview>> call() => server.change();
}

class _Change implements ChangeCycleTrackingUseCaseContract {
  _Change(this.server);
  final _FakeCycleServer server;
  @override
  Future<AppResult<CycleOverview>> call({
    required bool enabled,
    bool consent = false,
    bool deleteHistory = false,
  }) => server.change(
    enabled: enabled,
    consent: consent,
    deleteHistory: deleteHistory,
  );
}

class _Log implements LogCycleDayUseCaseContract {
  _Log(this.server);
  final _FakeCycleServer server;
  @override
  Future<AppResult<CycleOverview>> call(CycleDay day) => server.log(day);
}

class _List implements ListCycleDaysUseCaseContract {
  _List(this.server);
  final _FakeCycleServer server;
  @override
  Future<AppResult<List<CycleDay>>> call(DateTime from, DateTime to) async =>
      Result.success([
        for (final d in server.days.values)
          if (!d.date.isBefore(from) && !d.date.isAfter(to)) d,
      ]);
}

class _DeleteDay implements DeleteCycleDayUseCaseContract {
  _DeleteDay(this.server);
  final _FakeCycleServer server;
  @override
  Future<AppResult<Unit>> call(DateTime date) async {
    server.days.remove(date);
    return const Result.success(unit);
  }
}

class _DeleteAll implements DeleteCycleHistoryUseCaseContract {
  _DeleteAll(this.server);
  final _FakeCycleServer server;
  @override
  Future<AppResult<Unit>> call() async {
    server.days.clear();
    return const Result.success(unit);
  }
}

class _Adaptation implements GetTodayAdaptationUseCaseContract {
  TodayAdaptation value = const TodayAdaptation();
  @override
  Future<AppResult<TodayAdaptation>> call() async => Result.success(value);
}

class _Submit implements SubmitQuickCheckInUseCaseContract {
  _Submit(this.adaptation);
  final _Adaptation adaptation;
  QuickCheckIn? sent;
  @override
  Future<AppResult<Unit>> call(QuickCheckIn input) async {
    sent = input;
    // Como el servidor: dormir mal recorta series y lo explica.
    adaptation.value = const TodayAdaptation(
      volumeFactor: 0.8,
      reasons: [SessionAdaptationReason.highFatigue],
      fatigueCause: FatigueCause.poorSleep,
      checkInDone: true,
    );
    return const Result.success(unit);
  }
}

void main() {
  final today = DateTime(2026, 11, 4);

  CycleBloc cycleBloc(_FakeCycleServer server) => CycleBloc(
    getOverview: _Get(server),
    change: _Change(server),
    logDay: _Log(server),
    listDays: _List(server),
    deleteDay: _DeleteDay(server),
    deleteHistory: _DeleteAll(server),
    now: () => today,
  );

  group('Mi ciclo', () {
    test(
      'apagado por defecto; al activarlo se apunta hoy y se ve en el mes',
      () async {
        final server = _FakeCycleServer();
        final bloc = cycleBloc(server)..add(const CycleEvent.started());
        await bloc.stream.firstWhere((s) => !s.loading);
        expect(bloc.state.overview?.enabled, isFalse);

        bloc.add(const CycleEvent.enabled());
        await bloc.stream.firstWhere((s) => s.notice == CycleNotice.saved);
        expect(bloc.state.overview?.enabled, isTrue);

        bloc.add(
          CycleEvent.dayLogged(
            CycleDay(
              date: today,
              period: true,
              energy: CycleEnergy.low,
              symptoms: {CycleSymptom.cramps},
            ),
          ),
        );
        await bloc.stream.firstWhere((s) => s.days.containsKey(today));
        expect(bloc.state.overview?.phase, CyclePhase.period);
        expect(bloc.state.days[today]?.symptoms, {CycleSymptom.cramps});
        await bloc.close();
      },
    );

    test('desactivar borrando lo apuntado deja el mes vacío', () async {
      final server = _FakeCycleServer()..enabled = true;
      server.days[today] = CycleDay(date: today, period: true);
      final bloc = cycleBloc(server)..add(const CycleEvent.started());
      await bloc.stream.firstWhere((s) => s.days.isNotEmpty);

      bloc.add(const CycleEvent.disabled(deleteHistory: true));
      await bloc.stream.firstWhere((s) => s.notice == CycleNotice.disabled);
      expect(bloc.state.overview?.enabled, isFalse);
      expect(bloc.state.days, isEmpty);
      expect(server.days, isEmpty);
      await bloc.close();
    });
  });

  test(
    'registro rápido: tres toques y luego el porqué de la adaptación',
    () async {
      final adaptation = _Adaptation();
      final submit = _Submit(adaptation);
      final bloc = QuickCheckInBloc(getAdaptation: adaptation, submit: submit)
        ..add(const QuickCheckInEvent.started());
      await bloc.stream.firstWhere((s) => !s.loading);
      expect(bloc.state.asking, isTrue);

      bloc.add(
        const QuickCheckInEvent.submitted(
          QuickCheckIn(sleepQuality: 1, energy: 3, soreness: 1),
        ),
      );
      await bloc.stream.firstWhere((s) => s.adaptation?.checkInDone ?? false);
      expect(submit.sent?.sleepQuality, 1);
      expect(bloc.state.asking, isFalse);
      expect(bloc.state.adaptation?.fatigueCause, FatigueCause.poorSleep);

      bloc.add(const QuickCheckInEvent.editRequested());
      await bloc.stream.firstWhere((s) => s.editing);
      expect(bloc.state.asking, isTrue);
      await bloc.close();
    },
  );

  group('lectura del servidor', () {
    test('actividad con ritmo y adaptación con el ciclo', () {
      final activity = WellbeingExtraDtos.sportActivity({
        'blockId': 'b1',
        'start': '2026-11-03T17:00:00Z',
        'minutes': 25,
        'kind': 'RUN',
        'distanceMeters': 5000,
        'effort': 7,
        'paceSecondsPerKm': 300,
        'speedKmh': 12.0,
      });
      expect(activity.kind, ActivityKind.run);
      expect(activity.paceSecondsPerKm, 300);

      final page = WellbeingExtraDtos.activities({
        'items': [
          {'blockId': 'b2', 'start': '2026-11-01T10:00:00Z', 'minutes': 60},
        ],
        'page': 0,
        'totalPages': 2,
        'totalItems': 21,
      });
      expect(page, isA<TrainingPage<SportActivity>>());
      expect(page.hasMore, isTrue);
      expect(page.items.single.kind, isNull);

      final today = WellbeingExtraDtos.todayAdaptation({
        'volumeFactor': 0.9,
        'reasons': ['CYCLE_DISCOMFORT', 'SOMETHING_NEW'],
        'checkInDone': false,
      });
      expect(today.reasons, [SessionAdaptationReason.cycleDiscomfort]);
    });

    test('el día del ciclo viaja como fecha sin hora', () {
      expect(
        WellbeingExtraDtos.day(DateTime(2026, 3, 7, 23, 59)),
        '2026-03-07',
      );
      final body = WellbeingExtraDtos.cycleDayBody(
        CycleDay(
          date: DateTime(2026, 3, 7),
          symptoms: {CycleSymptom.headache},
          note: '  ',
        ),
      );
      expect(body['symptoms'], ['HEADACHE']);
      expect(body['note'], isNull);
    });
  });

  test('los avisos de racha, registro y clase llevan su texto y el aula', () {
    final at = DateTime.utc(2026, 11, 4, 8);
    final reminders = const ReminderComposer().compose([
      PlannedReminder(
        kind: ReminderKind.streakAtRisk,
        at: at,
        refId: '2026-11-04',
        count: 5,
      ),
      PlannedReminder(kind: ReminderKind.checkIn, at: at, refId: '2026-11-04'),
      PlannedReminder(
        kind: ReminderKind.classSoon,
        at: at,
        refId: 'c1',
        title: 'Cálculo',
        place: 'Aula 2.03',
        startsAt: at.add(const Duration(minutes: 15)),
      ),
    ], const TestReminderTexts());
    expect(reminders.map((r) => r.kind), [
      ReminderKind.streakAtRisk,
      ReminderKind.checkIn,
      ReminderKind.classSoon,
    ]);
    expect(reminders.first.body, 'streakAtRisk:5:-:-');
    expect(reminders.last.body, 'classSoon:-:Cálculo:Aula 2.03');
    expect(reminders.last.refId, 'c1');
    expect(reminders.map((r) => r.id).toSet(), hasLength(3));
  });
}
