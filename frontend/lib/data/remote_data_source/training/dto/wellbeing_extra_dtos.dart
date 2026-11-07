import '../../../../domain/enums/reminder_task_timing.dart';
import '../../../../domain/models/profile/notification_preferences.dart';
import '../../../../domain/models/reminders/reminder_options.dart';
import '../../../../domain/models/training/cycle.dart';
import '../../../../domain/models/training/health_consent.dart';
import '../../../../domain/models/training/session_adaptation.dart';
import '../../../../domain/models/training/sport_activity.dart';
import '../../../../domain/models/training/today_adaptation.dart';
import '../../../../domain/models/training/training_page.dart';

/// Traducción JSON ↔ dominio del ciclo, la adaptación de hoy, el deporte hecho
/// y los avisos opcionales (ADR 0033). Las fechas de día viajan como
/// `yyyy-MM-dd`.
abstract final class WellbeingExtraDtos {
  static String day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static HealthConsent healthConsent(Map<String, dynamic> json) =>
      HealthConsent(
        given: json['given'] as bool? ?? false,
        givenAt: _date(json['givenAt'])?.toLocal(),
        withdrawnAt: _date(json['withdrawnAt'])?.toLocal(),
      );

  static CycleDay cycleDay(Map<String, dynamic> json) => CycleDay(
    date: DateTime.parse(json['date'] as String),
    period: json['period'] as bool? ?? false,
    energy: CycleEnergy.fromApi(json['energy'] as String?),
    symptoms: {
      for (final s in (json['symptoms'] as List<dynamic>? ?? const []))
        ?CycleSymptom.fromApi(s as String),
    },
    note: json['note'] as String?,
  );

  static Map<String, dynamic> cycleDayBody(CycleDay day) => {
    'period': day.period,
    'energy': day.energy?.api,
    'symptoms': [for (final s in day.symptoms) s.api],
    'note': (day.note?.trim().isEmpty ?? true) ? null : day.note!.trim(),
  };

  static CycleOverview overview(Map<String, dynamic> json) => CycleOverview(
    enabled: json['enabled'] as bool? ?? false,
    consentedAt: _date(json['consentedAt'])?.toLocal(),
    phase: CyclePhase.fromApi(json['phase'] as String?),
    dayOfCycle: json['dayOfCycle'] as int?,
    cycleLength: json['cycleLength'] as int? ?? 28,
    nextPeriodFrom: _date(json['nextPeriodFrom']),
    today: json['today'] is Map<String, dynamic>
        ? cycleDay(json['today'] as Map<String, dynamic>)
        : null,
  );

  static TodayAdaptation todayAdaptation(Map<String, dynamic> json) =>
      TodayAdaptation(
        volumeFactor: (json['volumeFactor'] as num?)?.toDouble() ?? 1.0,
        reasons: [
          for (final r in (json['reasons'] as List<dynamic>? ?? const []))
            ?SessionAdaptationReason.fromApi(r as String),
        ],
        fatigueCause: FatigueCause.fromApi(json['fatigueCause'] as String?),
        checkInDone: json['checkInDone'] as bool? ?? false,
        sleepQuality: json['sleepQuality'] as int?,
        energy: json['energy'] as int?,
        soreness: json['soreness'] as int?,
      );

  static Map<String, dynamic> quickCheckInBody(QuickCheckIn input) => {
    'sleepQuality': input.sleepQuality,
    'energy': input.energy,
    'soreness': input.soreness,
  };

  static SportActivity sportActivity(Map<String, dynamic> json) =>
      SportActivity(
        blockId: json['blockId'] as String,
        start: DateTime.parse(json['start'] as String).toLocal(),
        minutes: json['minutes'] as int,
        title: json['title'] as String?,
        kind: ActivityKind.fromApi(json['kind'] as String?),
        distanceMeters: json['distanceMeters'] as int?,
        effort: json['effort'] as int?,
        paceSecondsPerKm: json['paceSecondsPerKm'] as int?,
        speedKmh: (json['speedKmh'] as num?)?.toDouble(),
        source: ActivitySource.fromApi(json['source'] as String?),
        elevationGainMeters: json['elevationGainMeters'] as int?,
      );

  static TrainingPage<SportActivity> activities(Map<String, dynamic> json) =>
      TrainingPage(
        items: [
          for (final item in (json['items'] as List<dynamic>? ?? const []))
            sportActivity(item as Map<String, dynamic>),
        ],
        page: json['page'] as int? ?? 0,
        totalPages: json['totalPages'] as int? ?? 0,
        totalItems: json['totalItems'] as int? ?? 0,
      );

  /// Lo que falte (servidores anteriores a ADR 0035) toma el valor por defecto.
  static ReminderOptions reminderOptions(Map<String, dynamic> json) {
    const defaults = ReminderOptions();
    final days = json['deadlineDaysBefore'];
    final at = ClockTime.tryParse(json['morningSummaryAt'] as String?);
    return ReminderOptions(
      streak: json['streak'] as bool? ?? true,
      checkIn: json['checkIn'] as bool? ?? true,
      classes: json['classes'] as bool? ?? true,
      eventLeadMinutes:
          (json['eventLeadMinutes'] as num?)?.toInt() ??
          defaults.eventLeadMinutes,
      deadlineDaysBefore: days is List && days.isNotEmpty
          ? ([for (final d in days.whereType<num>()) d.toInt()]..sort())
          : defaults.deadlineDaysBefore,
      taskTiming:
          ReminderTaskTiming.fromApi(json['taskTiming'] as String?) ??
          defaults.taskTiming,
      morningSummary: json['morningSummary'] as bool? ?? true,
      morningSummaryAt: at ?? defaults.morningSummaryAt,
    );
  }

  /// Se manda todo; con el resumen apagado la hora va nula (no cambia).
  static Map<String, dynamic> reminderOptionsBody(ReminderOptions o) => {
    'streak': o.streak,
    'checkIn': o.checkIn,
    'classes': o.classes,
    'eventLeadMinutes': o.eventLeadMinutes,
    'deadlineDaysBefore': o.deadlineDaysBefore,
    'taskTiming': o.taskTiming.apiValue,
    'morningSummary': o.morningSummary,
    'morningSummaryAt': o.morningSummary ? o.morningSummaryAt.apiValue : null,
  };
}
