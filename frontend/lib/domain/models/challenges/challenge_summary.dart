import 'package:freezed_annotation/freezed_annotation.dart';

part 'challenge_summary.freezed.dart';

/// Recuento de retos del usuario por estado. [active] incluye los que aún
/// no empiezan; [upcoming] los desglosa.
@freezed
abstract class ChallengeSummary with _$ChallengeSummary {
  const factory ChallengeSummary({
    required int active,
    required int completed,
    required int expired,
    @Default(0) int upcoming,
    required int total,
  }) = _ChallengeSummary;

  static const empty = ChallengeSummary(
    active: 0,
    completed: 0,
    expired: 0,
    total: 0,
  );
}
