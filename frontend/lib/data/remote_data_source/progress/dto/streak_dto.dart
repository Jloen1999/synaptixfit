import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/progress/streak.dart';

part 'streak_dto.freezed.dart';
part 'streak_dto.g.dart';

/// `StreakResponse` de la API.
@freezed
abstract class StreakDto with _$StreakDto {
  const factory StreakDto({
    @Default(0) int currentDays,
    @Default(0) int bestDays,
    @Default(false) bool activeToday,
    @Default(false) bool atRisk,
    int? nextMilestone,
    @Default(0) int daysToNextMilestone,
    @Default(0) double milestoneProgress,
    @Default(<int>[]) List<int> reachedMilestones,
    @Default(0) int freezesAvailable,
    @Default(<String>[]) List<String> frozenDays,
  }) = _StreakDto;

  const StreakDto._();

  factory StreakDto.fromJson(Map<String, dynamic> json) =>
      _$StreakDtoFromJson(json);

  Streak toDomain() => Streak(
    currentDays: currentDays,
    bestDays: bestDays < currentDays ? currentDays : bestDays,
    activeToday: activeToday,
    atRisk: atRisk,
    // Sin hito pendiente la API puede devolver 0: se normaliza a nulo.
    nextMilestone: nextMilestone == null || nextMilestone! <= 0
        ? null
        : nextMilestone,
    daysToNextMilestone: daysToNextMilestone < 0 ? 0 : daysToNextMilestone,
    milestoneProgress: milestoneProgress.clamp(0, 1).toDouble(),
    reachedMilestones: [...reachedMilestones]..sort(),
    freezesAvailable: freezesAvailable,
    frozenDays: [for (final d in frozenDays) DateTime.parse(d)],
  );
}
