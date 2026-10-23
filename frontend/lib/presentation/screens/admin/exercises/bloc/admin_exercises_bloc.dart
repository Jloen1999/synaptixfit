import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/admin/admin_exercise.dart';
import '../../../../../domain/models/admin/admin_page.dart';
import '../../../../../domain/models/admin/admin_queries.dart';
import '../../../../../domain/use_cases/admin/delete_admin_exercise_use_case.dart';
import '../../../../../domain/use_cases/admin/search_admin_exercises_use_case.dart';
import '../../../../../domain/use_cases/admin/set_admin_exercise_active_use_case.dart';
import '../../widgets/admin_status.dart';

part 'admin_exercises_bloc.freezed.dart';
part 'admin_exercises_event.dart';
part 'admin_exercises_state.dart';

/// Pestaña Ejercicios: catálogo con inactivos, activar/desactivar y borrar.
class AdminExercisesBloc
    extends Bloc<AdminExercisesEvent, AdminExercisesState> {
  AdminExercisesBloc({
    required this._search,
    required this._setActive,
    required this._delete,
  }) : super(const AdminExercisesState()) {
    on<AdminExercisesStarted>((_, emit) => _load(emit, page: 0));
    on<AdminExercisesRefreshed>((_, emit) => _load(emit, page: state.page));
    on<AdminExercisesQueryChanged>(_onQueryChanged);
    on<AdminExercisesPageRequested>((e, emit) => _load(emit, page: e.page));
    on<AdminExercisesActiveToggled>(_onActiveToggled);
    on<AdminExercisesDeleteRequested>(_onDelete);
  }

  static const pageSize = 20;

  final SearchAdminExercisesUseCaseContract _search;
  final SetAdminExerciseActiveUseCaseContract _setActive;
  final DeleteAdminExerciseUseCaseContract _delete;

  Future<void> _onQueryChanged(
    AdminExercisesQueryChanged event,
    Emitter<AdminExercisesState> emit,
  ) async {
    if (event.query == state.query && state.status == AdminStatus.ready) {
      return;
    }
    emit(state.copyWith(query: event.query));
    await _load(emit, page: 0);
  }

  Future<void> _load(
    Emitter<AdminExercisesState> emit, {
    required int page,
  }) async {
    emit(state.copyWith(status: AdminStatus.loading, page: page, error: null));
    final result = await _search(
      query: state.query,
      page: page,
      size: pageSize,
    );
    emit(
      result.fold(
        (exercises) =>
            state.copyWith(status: AdminStatus.ready, exercises: exercises),
        (error) => state.copyWith(status: AdminStatus.failure, error: error),
      ),
    );
  }

  Future<void> _onActiveToggled(
    AdminExercisesActiveToggled event,
    Emitter<AdminExercisesState> emit,
  ) async {
    if (state.busyId != null) return;
    final active = !event.exercise.active;
    emit(state.copyWith(busyId: event.exercise.id, effect: null));
    final result = await _setActive(event.exercise.id, active: active);
    emit(
      result.fold(
        (updated) => state.copyWith(
          busyId: null,
          exercises: _replace(updated),
          effect: AdminExercisesEffect.activeChanged(active: updated.active),
        ),
        (error) => state.copyWith(
          busyId: null,
          effect: AdminExercisesEffect.failure(error),
        ),
      ),
    );
  }

  Future<void> _onDelete(
    AdminExercisesDeleteRequested event,
    Emitter<AdminExercisesState> emit,
  ) async {
    if (state.busyId != null) return;
    emit(state.copyWith(busyId: event.exercise.id, effect: null));
    final result = await _delete(event.exercise.id);
    final deletion = result.valueOrNull;
    if (deletion == null) {
      emit(
        state.copyWith(
          busyId: null,
          effect: AdminExercisesEffect.failure(result.errorOrNull!),
        ),
      );
      return;
    }
    emit(state.copyWith(busyId: null));
    await _load(emit, page: state.page);
    emit(
      state.copyWith(
        effect: deletion.deleted
            ? const AdminExercisesEffect.deleted()
            : const AdminExercisesEffect.deactivatedInstead(),
      ),
    );
  }

  AdminPage<AdminExercise>? _replace(AdminExercise updated) {
    final page = state.exercises;
    if (page == null) return null;
    return page.copyWith(
      items: [
        for (final e in page.items)
          if (e.id == updated.id) updated else e,
      ],
    );
  }
}
