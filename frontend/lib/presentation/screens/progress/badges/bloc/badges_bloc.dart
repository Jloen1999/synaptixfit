import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/badge_category.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/progress/badge.dart';
import '../../../../../domain/use_cases/progress/change_badge_visibility_use_case.dart';
import '../../../../../domain/use_cases/progress/get_badge_catalog_use_case.dart';
import '../../../../../domain/use_cases/progress/share_badge_use_case.dart';

part 'badges_bloc.freezed.dart';
part 'badges_event.dart';
part 'badges_state.dart';

/// Catálogo de insignias: filtro por categoría, visibilidad y compartir.
class BadgesBloc extends Bloc<BadgesEvent, BadgesState> {
  BadgesBloc({
    required this._getCatalog,
    required this._changeVisibility,
    required this._shareBadge,
  }) : super(const BadgesState()) {
    on<BadgesStarted>(_onStarted);
    on<BadgesCategorySelected>(_onCategorySelected);
    on<BadgesVisibilityToggled>(_onVisibilityToggled);
    on<BadgesShareRequested>(_onShareRequested);
  }

  final GetBadgeCatalogUseCaseContract _getCatalog;
  final ChangeBadgeVisibilityUseCaseContract _changeVisibility;
  final ShareBadgeUseCaseContract _shareBadge;

  Future<void> _onStarted(
    BadgesStarted event,
    Emitter<BadgesState> emit,
  ) async {
    emit(state.copyWith(status: BadgesStatus.loading, error: null));
    final result = await _getCatalog();
    emit(
      result.fold(
        (badges) => state.copyWith(status: BadgesStatus.loaded, badges: badges),
        (error) => state.copyWith(status: BadgesStatus.failure, error: error),
      ),
    );
  }

  void _onCategorySelected(
    BadgesCategorySelected event,
    Emitter<BadgesState> emit,
  ) => emit(state.copyWith(category: event.category));

  Future<void> _onVisibilityToggled(
    BadgesVisibilityToggled event,
    Emitter<BadgesState> emit,
  ) async {
    final id = event.badge.id;
    if (!event.badge.earned || state.busyIds.contains(id)) return;
    emit(state.copyWith(busyIds: {...state.busyIds, id}));
    final result = await _changeVisibility(badgeId: id, visible: event.visible);
    final busy = {...state.busyIds}..remove(id);
    result.fold(
      (updated) {
        emit(
          state.copyWith(
            busyIds: busy,
            badges: [for (final b in state.badges) b.id == id ? updated : b],
            feedback: BadgesFeedback.visibilityChanged(
              visible: updated.visible,
            ),
          ),
        );
      },
      (error) => emit(
        state.copyWith(busyIds: busy, feedback: BadgesFeedback.failed(error)),
      ),
    );
    emit(state.copyWith(feedback: null));
  }

  Future<void> _onShareRequested(
    BadgesShareRequested event,
    Emitter<BadgesState> emit,
  ) async {
    final id = event.badge.id;
    if (!event.badge.earned || state.busyIds.contains(id)) return;
    emit(state.copyWith(busyIds: {...state.busyIds, id}));
    final result = await _shareBadge(
      badge: event.badge,
      message: event.message,
    );
    final busy = {...state.busyIds}..remove(id);
    emit(
      state.copyWith(
        busyIds: busy,
        feedback: result.fold(
          (_) => const BadgesFeedback.shared(),
          BadgesFeedback.failed,
        ),
      ),
    );
    emit(state.copyWith(feedback: null));
  }
}
