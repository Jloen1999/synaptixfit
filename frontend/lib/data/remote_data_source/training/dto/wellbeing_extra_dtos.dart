import '../../../../domain/models/reminders/reminder_options.dart';
import '../../../../domain/models/training/cycle.dart';
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

  static ReminderOptions reminderOptions(Map<String, dynamic> json) =>
      ReminderOptions(
        streak: json['streak'] as bool? ?? true,
        checkIn: json['checkIn'] as bool? ?? true,
        classes: json['classes'] as bool? ?? true,
      );

  static Map<String, dynamic> reminderOptionsBody(ReminderOptions o) => {
    'streak': o.streak,
    'checkIn': o.checkIn,
    'classes': o.classes,
  };
}
