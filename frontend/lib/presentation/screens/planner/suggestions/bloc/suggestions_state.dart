part of 'suggestions_bloc.dart';

enum SuggestionsStatus { idle, generating, ready, accepting }

@freezed
abstract class SuggestionsState with _$SuggestionsState {
  const factory SuggestionsState({
    required DateTime currentWeek,
    @Default(0) int weekOffset,
    @Default(10) double studyHours,
    @Default(3) int sportSessions,
    @Default(SuggestionsStatus.idle) SuggestionsStatus status,
    WeekSuggestion? suggestion,
    @Default(<int>{}) Set<int> selected,

    /// Bloques propuestos que ya han empezado (no se pueden aceptar).
    @Default(<int>{}) Set<int> expired,
    AppError? error,
    SuggestionsNotice? notice,
    @Default(0) int noticeId,
  }) = _SuggestionsState;

  const SuggestionsState._();

  DateTime get weekStart => PlannerWeek.shift(currentWeek, weekOffset);
}

@freezed
sealed class SuggestionsNotice with _$SuggestionsNotice {
  /// Bloques creados ([created]) y los que fallaron ([failed]).
  const factory SuggestionsNotice.accepted({
    required int created,
    required int failed,
    AppError? firstError,
  }) = SuggestionsNoticeAccepted;

  const factory SuggestionsNotice.failure(AppError error) =
      SuggestionsNoticeFailure;
}
