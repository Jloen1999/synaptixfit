import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/training/session_history.dart';
import 'session_dto.dart';

part 'session_history_dto.freezed.dart';
part 'session_history_dto.g.dart';

@freezed
abstract class PersonalRecordDto with _$PersonalRecordDto {
  const factory PersonalRecordDto({
    required String exerciseId,
    String? exerciseName,
    required String kind,
    double? weightKg,
    required int reps,
    required String sessionId,
    required DateTime achievedAt,
  }) = _PersonalRecordDto;

  const PersonalRecordDto._();

  factory PersonalRecordDto.fromJson(Map<String, dynamic> json) =>
      _$PersonalRecordDtoFromJson(json);

  PersonalRecord toDomain() => PersonalRecord(
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    kind: PersonalRecordKind.fromApi(kind),
    weightKg: weightKg,
    reps: reps,
    sessionId: sessionId,
    achievedAt: achievedAt,
  );
}

@freezed
abstract class SessionHistoryDto with _$SessionHistoryDto {
  const factory SessionHistoryDto({
    required SessionDto session,
    String? routineName,
    String? dayName,
    int? dayNumber,
    int? weekNumber,
    @Default(<PersonalRecordDto>[]) List<PersonalRecordDto> records,
  }) = _SessionHistoryDto;

  const SessionHistoryDto._();

  factory SessionHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$SessionHistoryDtoFromJson(json);

  SessionHistoryEntry toDomain() => SessionHistoryEntry(
    session: session.toDomain(),
    routineName: routineName,
    dayName: dayName,
    dayNumber: dayNumber,
    weekNumber: weekNumber,
    records: [for (final r in records) r.toDomain()],
  );
}
