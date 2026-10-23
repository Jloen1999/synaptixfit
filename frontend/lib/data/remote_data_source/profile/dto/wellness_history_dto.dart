import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/profile/fitness_goal.dart';
import '../../../../domain/enums/profile/goal_suggestion_source.dart';
import '../../../../domain/models/profile/wellness_history.dart';
import 'academic_profile_dto.dart';

part 'wellness_history_dto.freezed.dart';
part 'wellness_history_dto.g.dart';

@freezed
abstract class WeightRecordDto with _$WeightRecordDto {
  const factory WeightRecordDto({
    required String id,
    required double weightKg,
    double? bmi,
    required String recordedAt,
  }) = _WeightRecordDto;

  const WeightRecordDto._();

  factory WeightRecordDto.fromJson(Map<String, dynamic> json) =>
      _$WeightRecordDtoFromJson(json);

  WeightRecord toDomain() => WeightRecord(
    id: id,
    weightKg: weightKg,
    bmi: bmi,
    recordedAt: DateTime.parse(recordedAt).toLocal(),
  );
}

@freezed
abstract class GoalHistoryDto with _$GoalHistoryDto {
  const factory GoalHistoryDto({
    required String id,
    String? goal,
    String? goalLabel,
    String? previousGoal,
    String? previousGoalLabel,
    String? startDate,
    String? endDate,
    bool? active,
  }) = _GoalHistoryDto;

  const GoalHistoryDto._();

  factory GoalHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$GoalHistoryDtoFromJson(json);

  GoalHistoryEntry toDomain() => GoalHistoryEntry(
    id: id,
    goal: FitnessGoal.fromApi(goal),
    goalLabel: goalLabel,
    previousGoal: FitnessGoal.fromApi(previousGoal),
    previousGoalLabel: previousGoalLabel,
    startDate: parseLocalDate(startDate),
    endDate: parseLocalDate(endDate),
    active: active ?? false,
  );
}

@freezed
abstract class GoalSuggestionItemDto with _$GoalSuggestionItemDto {
  const factory GoalSuggestionItemDto({
    String? goal,
    String? label,
    String? reason,
  }) = _GoalSuggestionItemDto;

  factory GoalSuggestionItemDto.fromJson(Map<String, dynamic> json) =>
      _$GoalSuggestionItemDtoFromJson(json);
}

@freezed
abstract class GoalSuggestionsDto with _$GoalSuggestionsDto {
  const factory GoalSuggestionsDto({
    String? source,
    @Default(<GoalSuggestionItemDto>[]) List<GoalSuggestionItemDto> suggestions,
  }) = _GoalSuggestionsDto;

  const GoalSuggestionsDto._();

  factory GoalSuggestionsDto.fromJson(Map<String, dynamic> json) =>
      _$GoalSuggestionsDtoFromJson(json);

  /// Descarta las sugerencias con un objetivo desconocido.
  GoalSuggestions toDomain() => GoalSuggestions(
    source: GoalSuggestionSource.fromApi(source),
    suggestions: [
      for (final item in suggestions)
        if (FitnessGoal.fromApi(item.goal) case final goal?)
          GoalSuggestion(goal: goal, label: item.label, reason: item.reason),
    ],
  );
}
