import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/social/app_notification.dart';
import '../../../../../domain/use_cases/notifications/delete_notification_use_case.dart';
import '../../../../../domain/use_cases/notifications/get_notifications_use_case.dart';
import '../../../../../domain/use_cases/notifications/mark_all_notifications_read_use_case.dart';
import '../../../../../domain/use_cases/notifications/mark_notification_read_use_case.dart';
import '../../widgets/social_feedback.dart';

part 'notifications_bloc.freezed.dart';
part 'notifications_event.dart';
part 'notifications_state.dart';

/// Bandeja de notificaciones: filtro de no leídas, marcar leídas y borrar.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required this._getNotifications,
    required this._markRead,
    required this._markAllRead,
    required this._deleteNotification,
    this.pageSize = 20,
  }) : super(const NotificationsState()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsFilterChanged>(_onFilterChanged);
    on<NotificationsRefreshed>(_onRefreshed);
    on<NotificationsNextPageRequested>(_onNextPage);
    on<NotificationsOpened>(_onOpened);
    on<NotificationsAllMarkedRead>(_onAllMarkedRead);
    on<NotificationsDeleted>(_onDeleted);
  }

  final GetNotificationsUseCaseContract _getNotifications;
  final MarkNotificationReadUseCaseContract _markRead;
  final MarkAllNotificationsReadUseCaseContract _markAllRead;
  final DeleteNotificationUseCaseContract _deleteNotification;
  final int pageSize;

  Future<void> _onStarted(
    NotificationsStarted event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsState(unreadOnly: state.unreadOnly));
    await _loadFirstPage(emit);
  }

  Future<void> _onFilterChanged(
    NotificationsFilterChanged event,
    Emitter<NotificationsState> emit,
  ) async {
    if (event.unreadOnly == state.unreadOnly) return;
    emit(NotificationsState(unreadOnly: event.unreadOnly));
    await _loadFirstPage(emit);
  }

  Future<void> _onRefreshed(
    NotificationsRefreshed event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(refreshing: true));
    await _loadFirstPage(emit);
    emit(state.copyWith(refreshing: false));
  }

  Future<void> _onNextPage(
    NotificationsNextPageRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (!state.hasMore ||
        state.loadingMore ||
        state.status != SocialLoadStatus.loaded) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    final unreadOnly = state.unreadOnly;
    final result = await _getNotifications(
      unreadOnly: unreadOnly,
      page: state.page + 1,
      size: pageSize,
    );
    if (unreadOnly != state.unreadOnly) return;
    result.fold(
      (page) {
        final known = state.items.map((n) => n.id).toSet();
        emit(
          state.copyWith(
            loadingMore: false,
            items: [
              ...state.items,
              ...page.items.where((n) => !known.contains(n.id)),
            ],
            page: page.page,
            hasMore: page.hasMore,
          ),
        );
      },
      (error) => _notify(
        emit,
        state.copyWith(loadingMore: false),
        SocialFeedback.error(error),
      ),
    );
  }

  /// Marca como leída al abrirla (optimista). Si falla, se revierte.
  Future<void> _onOpened(
    NotificationsOpened event,
    Emitter<NotificationsState> emit,
  ) async {
    final original = _find(event.notificationId);
    if (original == null || original.read) return;
    emit(_replace(original.copyWith(read: true)));
    final result = await _markRead(notificationId: original.id);
    result.fold(
      (updated) => emit(_replace(updated)),
      (error) => _notify(emit, _replace(original), SocialFeedback.error(error)),
    );
  }

  Future<void> _onAllMarkedRead(
    NotificationsAllMarkedRead event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.markingAll) return;
    emit(state.copyWith(markingAll: true));
    final result = await _markAllRead();
    result.fold(
      (_) => _notify(
        emit,
        state.copyWith(
          markingAll: false,
          items: state.unreadOnly
              ? const []
              : [for (final n in state.items) n.copyWith(read: true)],
          hasMore: state.unreadOnly ? false : state.hasMore,
        ),
        const SocialFeedback.message(SocialMessage.allNotificationsRead),
      ),
      (error) => _notify(
        emit,
        state.copyWith(markingAll: false),
        SocialFeedback.error(error),
      ),
    );
  }

  /// Borrado optimista: se quita al deslizar y se repone si la API falla.
  Future<void> _onDeleted(
    NotificationsDeleted event,
    Emitter<NotificationsState> emit,
  ) async {
    final index = state.items.indexWhere((n) => n.id == event.notificationId);
    if (index < 0) return;
    final removed = state.items[index];
    emit(state.copyWith(items: [...state.items]..removeAt(index)));
    final result = await _deleteNotification(notificationId: removed.id);
    result.fold(
      (_) => _notify(
        emit,
        state,
        const SocialFeedback.message(SocialMessage.notificationDeleted),
      ),
      (error) {
        final items = [...state.items];
        items.insert(index.clamp(0, items.length), removed);
        _notify(
          emit,
          state.copyWith(items: items),
          SocialFeedback.error(error),
        );
      },
    );
  }

  Future<void> _loadFirstPage(Emitter<NotificationsState> emit) async {
    final unreadOnly = state.unreadOnly;
    final result = await _getNotifications(
      unreadOnly: unreadOnly,
      size: pageSize,
    );
    if (unreadOnly != state.unreadOnly) return;
    result.fold(
      (page) => emit(
        state.copyWith(
          status: SocialLoadStatus.loaded,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          error: null,
        ),
      ),
      (error) => state.status == SocialLoadStatus.loaded
          ? _notify(emit, state, SocialFeedback.error(error))
          : emit(
              state.copyWith(status: SocialLoadStatus.failure, error: error),
            ),
    );
  }

  AppNotification? _find(String id) {
    for (final n in state.items) {
      if (n.id == id) return n;
    }
    return null;
  }

  NotificationsState _replace(AppNotification notification) => state.copyWith(
    items: [
      for (final n in state.items) n.id == notification.id ? notification : n,
    ],
  );

  void _notify(
    Emitter<NotificationsState> emit,
    NotificationsState next,
    SocialFeedback feedback,
  ) {
    emit(next.copyWith(feedback: feedback));
    emit(next.copyWith(feedback: null));
  }
}
