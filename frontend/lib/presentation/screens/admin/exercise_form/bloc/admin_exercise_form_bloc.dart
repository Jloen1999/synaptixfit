import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/admin/admin_exercise.dart';
import '../../../../../domain/use_cases/admin/create_admin_exercise_use_case.dart';
import '../../../../../domain/use_cases/admin/get_admin_exercise_options_use_case.dart';
import '../../../../../domain/use_cases/admin/get_admin_exercise_names_use_case.dart';
import '../../../../../domain/use_cases/admin/get_admin_exercise_use_case.dart';
import '../../../../../domain/use_cases/admin/suggest_admin_exercise_names_use_case.dart';
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
    required this._getNames,
    required this._suggestNames,
    required this._create,
    required this._update,
  }) : super(const AdminExerciseFormState()) {
    on<AdminExerciseFormStarted>(_onStarted);
    on<AdminExerciseFormDraftChanged>(
      (e, emit) => emit(state.copyWith(draft: e.draft)),
    );
    on<AdminExerciseFormNamesSuggested>(_onNamesSuggested);
    on<AdminExerciseFormSubmitted>(_onSubmitted);
  }

  final GetAdminExerciseOptionsUseCaseContract _getOptions;
  final GetAdminExerciseUseCaseContract _getExercise;
  final GetAdminExerciseNamesUseCaseContract _getNames;
  final SuggestAdminExerciseNamesUseCaseContract _suggestNames;
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
      // Si no se pueden leer sus nombres en otros idiomas, se guardan sin
      // tocarlos (translations nulo) en vez de borrarlos.
      final names = (await _getNames(id)).valueOrNull;
      draft = AdminExerciseDraft.fromExercise(
        value,
      ).copyWith(translations: names);
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

  Future<void> _onNamesSuggested(
    AdminExerciseFormNamesSuggested event,
    Emitter<AdminExerciseFormState> emit,
  ) async {
    final draft = state.draft;
    final current = draft.translations;
    if (state.suggestingNames || current == null || !draft.isNameValid) return;
    if (event.onlyIfEmpty && !current.isEmpty) return;
    emit(state.copyWith(suggestingNames: true, namesError: null));
    final result = await _suggestNames(draft.name);
    emit(
      result.fold(
        (names) => state.copyWith(
          suggestingNames: false,
          draft: state.draft.copyWith(translations: names),
          namesRevision: state.namesRevision + 1,
        ),
        (error) => state.copyWith(suggestingNames: false, namesError: error),
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
