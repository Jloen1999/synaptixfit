part of 'notifications_bloc.dart';

@freezed
abstract class NotificationsState with _$NotificationsState {
  const factory NotificationsState({
    @Default(SocialLoadStatus.loading) SocialLoadStatus status,
    @Default(false) bool unreadOnly,
    @Default(<AppNotification>[]) List<AppNotification> items,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(false) bool loadingMore,
    @Default(false) bool refreshing,
    @Default(false) bool markingAll,
    AppError? error,
    SocialFeedback? feedback,
  }) = _NotificationsState;

  const NotificationsState._();

  bool get hasUnread => items.any((n) => !n.read);
}
