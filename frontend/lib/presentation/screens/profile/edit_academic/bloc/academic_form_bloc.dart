import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/profile/academic_profile.dart';
import '../../../../../domain/models/profile/catalog.dart';
import '../../../../../domain/use_cases/profile/get_profile_summary_use_case.dart';
import '../../../../../domain/use_cases/profile/save_academic_profile_use_case.dart';

part 'academic_form_bloc.freezed.dart';
part 'academic_form_event.dart';
part 'academic_form_state.dart';

/// Formulario del perfil académico (onboarding y edición).
class AcademicFormBloc extends Bloc<AcademicFormEvent, AcademicFormState> {
  AcademicFormBloc({required this._getSummary, required this._saveProfile})
    : super(const AcademicFormState()) {
    on<AcademicFormStarted>(_onStarted);
    on<AcademicFormDegreeSelected>(
      (e, emit) => emit(state.copyWith(selectedDegree: e.degree)),
    );
    on<AcademicFormDegreeCleared>(
      (_, emit) => emit(state.copyWith(selectedDegree: null)),
    );
    on<AcademicFormSubmitted>(_onSubmitted);
  }

  final GetProfileSummaryUseCaseContract _getSummary;
  final SaveAcademicProfileUseCaseContract _saveProfile;

  Future<void> _onStarted(
    AcademicFormStarted event,
    Emitter<AcademicFormState> emit,
  ) async {
    if (!event.loadExisting) {
      emit(state.copyWith(status: AcademicFormStatus.ready));
      return;
    }
    emit(state.copyWith(status: AcademicFormStatus.loading, loadError: null));
    final result = await _getSummary();
    emit(
      result.fold(
        (summary) => state.copyWith(
          status: AcademicFormStatus.ready,
          initial: summary.academic,
        ),
        (error) => state.copyWith(
          status: AcademicFormStatus.failure,
          loadError: error,
        ),
      ),
    );
  }

  /// Si hay carrera del catálogo elegida se envía su id (el backend completa
  /// universidad y carrera y la vincula); si no, los textos escritos a mano.
  Future<void> _onSubmitted(
    AcademicFormSubmitted event,
    Emitter<AcademicFormState> emit,
  ) async {
    emit(state.copyWith(saving: true, actionError: null, saved: null));
    final degree = state.selectedDegree;
    final draft = degree == null
        ? event.draft
        : event.draft.copyWith(
            degreeId: degree.id,
            degree: degree.name,
            university: degree.universityName ?? event.draft.university,
          );
    final result = await _saveProfile(draft);
    emit(
      result.fold(
        (profile) =>
            state.copyWith(saving: false, initial: profile, saved: profile),
        (error) => state.copyWith(saving: false, actionError: error),
      ),
    );
  }
}
