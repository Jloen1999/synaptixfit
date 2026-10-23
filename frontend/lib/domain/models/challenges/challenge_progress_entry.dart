import 'package:freezed_annotation/freezed_annotation.dart';

part 'challenge_progress_entry.freezed.dart';

/// Registro de progreso manual de un reto o de una de sus tareas.
@freezed
abstract class ChallengeProgressEntry with _$ChallengeProgressEntry {
  const factory ChallengeProgressEntry({
    required String id,
    String? milestoneId,
    required double amount,
    required DateTime recordedAt,
  }) = _ChallengeProgressEntry;
}
