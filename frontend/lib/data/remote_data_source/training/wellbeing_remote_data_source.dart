import 'package:dio/dio.dart';

import '../../../domain/models/reminders/reminder_options.dart';
import '../../../domain/models/training/cycle.dart';
import '../../../domain/models/training/sport_activity.dart';
import '../../../domain/models/training/today_adaptation.dart';
import '../../../domain/models/training/training_page.dart';
import '../api/api_client.dart';
import 'dto/wellbeing_extra_dtos.dart';

/// Llamadas de bienestar: ciclo (`/training/cycle`), adaptación de hoy y
/// registro rápido (`/training`), deporte hecho (`/planner/past-activities`) y
/// avisos opcionales (`/notifications/reminder-options`).
class WellbeingRemoteDataSource {
  WellbeingRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _training = '/api/v1/training';

  Future<CycleOverview> getCycle() async {
    final r = await _dio.get<Map<String, dynamic>>('$_training/cycle');
    return WellbeingExtraDtos.overview(r.data!);
  }

  Future<CycleOverview> changeCycleTracking({
    required bool enabled,
    required bool consent,
    required bool deleteHistory,
  }) async {
    final r = await _dio.put<Map<String, dynamic>>(
      '$_training/cycle/settings',
      data: {
        'enabled': enabled,
        'consent': consent,
        'deleteHistory': deleteHistory,
      },
    );
    return WellbeingExtraDtos.overview(r.data!);
  }

  Future<CycleOverview> logCycleDay(CycleDay day) async {
    final r = await _dio.put<Map<String, dynamic>>(
      '$_training/cycle/days/${WellbeingExtraDtos.day(day.date)}',
      data: WellbeingExtraDtos.cycleDayBody(day),
    );
    return WellbeingExtraDtos.overview(r.data!);
  }

  Future<List<CycleDay>> listCycleDays(DateTime from, DateTime to) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_training/cycle/days',
      queryParameters: {
        'from': WellbeingExtraDtos.day(from),
        'to': WellbeingExtraDtos.day(to),
      },
    );
    return [
      for (final d in (r.data!['days'] as List<dynamic>? ?? const []))
        WellbeingExtraDtos.cycleDay(d as Map<String, dynamic>),
    ];
  }

  Future<void> deleteCycleDay(DateTime date) => _dio.delete<void>(
    '$_training/cycle/days/${WellbeingExtraDtos.day(date)}',
  );

  Future<void> deleteCycleHistory() =>
      _dio.delete<void>('$_training/cycle/days');

  Future<TodayAdaptation> getTodayAdaptation() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_training/adaptation/today',
    );
    return WellbeingExtraDtos.todayAdaptation(r.data!);
  }

  Future<void> submitQuickCheckIn(QuickCheckIn input) => _dio.put<void>(
    '$_training/check-ins/today',
    data: WellbeingExtraDtos.quickCheckInBody(input),
  );

  Future<TrainingPage<SportActivity>> listSportActivities({
    required int page,
    required int size,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/api/v1/planner/past-activities',
      queryParameters: {'page': page, 'size': size},
    );
    return WellbeingExtraDtos.activities(r.data!);
  }

  Future<ReminderOptions> getReminderOptions() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/api/v1/notifications/reminder-options',
    );
    return WellbeingExtraDtos.reminderOptions(r.data!);
  }

  Future<ReminderOptions> changeReminderOptions(ReminderOptions o) async {
    final r = await _dio.put<Map<String, dynamic>>(
      '/api/v1/notifications/reminder-options',
      data: WellbeingExtraDtos.reminderOptionsBody(o),
    );
    return WellbeingExtraDtos.reminderOptions(r.data!);
  }
}
