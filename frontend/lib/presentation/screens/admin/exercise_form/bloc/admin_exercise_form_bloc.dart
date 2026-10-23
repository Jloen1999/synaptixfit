import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/admin/admin_exercise.dart';
import '../../../../../domain/use_cases/admin/create_admin_exercise_use_case.dart';
import '../../../../../domain/use_cases/admin/get_admin_exercise_options_use_case.dart';
import '../../../../../domain/use_cases/admin/get_admin_exercise_use_case.dart';
import '../../../../../domain/use_cases/admin/update_admin_exercise_use_case.dart';
import '../../widgets/admin_status.dart';

part 'admin_exercise_form_bloc.freezed.dart';
part 'admin_exercise_form_event.dart';
part 'admin_exercise_form_state.dart';

/// Formulario de alta y edición de un ejercicio del catálogo.
class AdminExerciseFormBloc
    extends Bloc<AdminExerciseFormEvent, AdminExerciseFormState> {
  AdminExerciseFormBloc({
    required this._getOptions,
    required this._getExercise,
    required this._create,
    required this._update,
  }) : super(const AdminExerciseFormState()) {
    on<AdminExerciseFormStarted>(_onStarted);
    on<AdminExerciseFormDraftChanged>(
      (e, emit) => emit(state.copyWith(draft: e.draft)),
    );
    on<AdminExerciseFormSubmitted>(_onSubmitted);
  }

  final GetAdminExerciseOptionsUseCaseContract _getOptions;
  final GetAdminExerciseUseCaseContract _getExercise;
  final CreateAdminExerciseUseCaseContract _create;
  final UpdateAdminExerciseUseCaseContract _update;

  Future<void> _onStarted(
    AdminExerciseFormStarted event,
    Emitter<AdminExerciseFormState> emit,
  ) async {
    final id = event.exerciseId;
    emit(
      state.copyWith(status: AdminStatus.loading, exerciseId: id, error: null),
    );
    final options = await _getOptions();
    final optionsError = options.errorOrNull;
    if (optionsError != null) {
      emit(state.copyWith(status: AdminStatus.failure, error: optionsError));
      return;
    }
    var draft = const AdminExerciseDraft();
    var active = true;
    if (id != null) {
      final exercise = await _getExercise(id);
      final value = exercise.valueOrNull;
      if (value == null) {
        emit(
          state.copyWith(
            status: AdminStatus.failure,
            error: exercise.errorOrNull,
          ),
        );
        return;
      }
      draft = AdminExerciseDraft.fromExercise(value);
      active = value.active;
    }
    emit(
      state.copyWith(
        status: AdminStatus.ready,
        options: options.valueOrNull!,
        draft: draft,
        active: active,
      ),
    );
  }

  Future<void> _onSubmitted(
    AdminExerciseFormSubmitted event,
    Emitter<AdminExerciseFormState> emit,
  ) async {
    if (state.submitting) return;
    if (!state.draft.isValid) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(state.copyWith(submitting: true, showErrors: true, effect: null));
    final id = state.exerciseId;
    final result = id == null
        ? await _create(state.draft)
        : await _update(id, state.draft);
    emit(
      result.fold(
        (exercise) => state.copyWith(
          submitting: false,
          effect: AdminExerciseFormEffect.saved(exercise),
        ),
        (error) => state.copyWith(
          submitting: false,
          effect: AdminExerciseFormEffect.failure(error),
        ),
      ),
    );
  }
}
