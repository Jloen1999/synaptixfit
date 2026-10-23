part of 'weekly_load_bloc.dart';

enum WeeklyLoadStatus { loading, ready, failure }

@freezed
abstract class WeeklyLoadState with _$WeeklyLoadState {
  const factory WeeklyLoadState({
    DateTime? weekStart,
    @Default(WeeklyLoadStatus.loading) WeeklyLoadStatus status,
    WeekBalance? balance,
    WeeklyLoad? load,
    AppError? error,
    @Default(false) bool saving,
    @Default(false) bool syncing,
    WeeklyLoadNotice? notice,
    @Default(0) int noticeId,
  }) = _WeeklyLoadState;
}

@freezed
sealed class WeeklyLoadNotice with _$WeeklyLoadNotice {
  const factory WeeklyLoadNotice.saved() = WeeklyLoadNoticeSaved;

  const factory WeeklyLoadNotice.synced({
    required int xpAwarded,
    Account? account,
  }) = WeeklyLoadNoticeSynced;

  const factory WeeklyLoadNotice.failure(AppError error) =
      WeeklyLoadNoticeFailure;
}
