import '../../../../domain/models/training/training_week.dart';

/// JSON de `GET /training/week` (ADR 0055). Pequeño y sin anidar: se lee a mano.
class TrainingWeekDto {
  const TrainingWeekDto({
    required this.days,
    required this.done,
    required this.total,
  });

  factory TrainingWeekDto.fromJson(Map<String, dynamic> json) =>
      TrainingWeekDto(
        days: [
          for (final d in (json['days'] as List<dynamic>? ?? const []))
            TrainingWeekDayDto.fromJson(d as Map<String, dynamic>),
        ],
        done: json['done'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
      );

  final List<TrainingWeekDayDto> days;
  final int done;
  final int total;

  TrainingWeek toDomain() => TrainingWeek(
    days: [for (final d in days) d.toDomain()],
    done: done,
    total: total,
  );
}

/// Un día de [TrainingWeekDto]; `state` llega como `DONE`, `PLANNED` o `FREE`.
class TrainingWeekDayDto {
  const TrainingWeekDayDto({
    required this.date,
    required this.state,
    required this.today,
    this.sessionId,
  });

  factory TrainingWeekDayDto.fromJson(Map<String, dynamic> json) =>
      TrainingWeekDayDto(
        date: json['date'] as String,
        state: json['state'] as String?,
        today: json['today'] as bool? ?? false,
        sessionId: json['sessionId'] as String?,
      );

  final String date;
  final String? state;
  final bool today;
  final String? sessionId;

  TrainingWeekDay toDomain() => TrainingWeekDay(
    date: DateTime.parse(date),
    state: TrainingDayState.fromApi(state),
    today: today,
    sessionId: sessionId,
  );
}
