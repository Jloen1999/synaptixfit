part of 'notifications_bloc.dart';

@freezed
sealed class NotificationsEvent with _$NotificationsEvent {
  const factory NotificationsEvent.started() = NotificationsStarted;

  const factory NotificationsEvent.filterChanged({required bool unreadOnly}) =
      NotificationsFilterChanged;

  const factory NotificationsEvent.refreshed() = NotificationsRefreshed;

  const factory NotificationsEvent.nextPageRequested() =
      NotificationsNextPageRequested;

  /// El usuario toca la notificación: se marca leída (la página navega).
  const factory NotificationsEvent.opened(String notificationId) =
      NotificationsOpened;

  const factory NotificationsEvent.allMarkedRead() = NotificationsAllMarkedRead;

  const factory NotificationsEvent.deleted(String notificationId) =
      NotificationsDeleted;
}
