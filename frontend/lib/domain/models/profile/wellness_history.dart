import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/profile/fitness_goal.dart';
import '../../enums/profile/goal_suggestion_source.dart';

part 'wellness_history.freezed.dart';

/// Registro del historial de peso.
@freezed
abstract class WeightRecord with _$WeightRecord {
  const factory WeightRecord({
    required String id,
    required double weightKg,
    double? bmi,
    required DateTime recordedAt,
  }) = _WeightRecord;
}

/// Tramo del historial de objetivos.
@freezed
abstract class GoalHistoryEntry with _$GoalHistoryEntry {
  const factory GoalHistoryEntry({
    required String id,
    FitnessGoal? goal,
    String? goalLabel,
    FitnessGoal? previousGoal,
    String? previousGoalLabel,
    DateTime? startDate,
    DateTime? endDate,
    @Default(false) bool active,
  }) = _GoalHistoryEntry;
}

/// Objetivo sugerido con su motivo.
@freezed
abstract class GoalSuggestion with _$GoalSuggestion {
  const factory GoalSuggestion({
    required FitnessGoal goal,
    String? label,
    String? reason,
  }) = _GoalSuggestion;
}

/// Sugerencias de objetivo y su origen (IA o reglas).
@freezed
abstract class GoalSuggestions with _$GoalSuggestions {
  const factory GoalSuggestions({
    required GoalSuggestionSource source,
    required List<GoalSuggestion> suggestions,
  }) = _GoalSuggestions;
}
