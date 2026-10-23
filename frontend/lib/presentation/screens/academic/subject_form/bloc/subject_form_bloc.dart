import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../../domain/use_cases/academic/assign_subject_semester_use_case.dart';
import '../../../../../domain/use_cases/academic/clear_subject_semester_use_case.dart';
import '../../../../../domain/use_cases/academic/create_subject_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subject_semester_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subject_use_case.dart';
import '../../../../../domain/use_cases/academic/update_subject_use_case.dart';

part 'subject_form_bloc.freezed.dart';
part 'subject_form_event.dart';
part 'subject_form_state.dart';

/// Alta y edición de una asignatura con su curso y semestre.
class SubjectFormBloc extends Bloc<SubjectFormEvent, SubjectFormState> {
  SubjectFormBloc({
    required this._getSubject,
    required this._getSemester,
    required this._createSubject,
    required this._updateSubject,
    required this._assignSemester,
    required this._clearSemester,
  }) : super(const SubjectFormState()) {
    on<SubjectFormStarted>(_onStarted);
    on<SubjectFormSubmitted>(_onSubmitted);
  }

  final GetSubjectUseCaseContract _getSubject;
  final GetSubjectSemesterUseCaseContract _getSemester;
  final CreateSubjectUseCaseContract _createSubject;
  final UpdateSubjectUseCaseContract _updateSubject;
  final AssignSubjectSemesterUseCaseContract _assignSemester;
  final ClearSubjectSemesterUseCaseContract _clearSemester;

  Future<void> _onStarted(
    SubjectFormStarted event,
    Emitter<SubjectFormState> emit,
  ) async {
    final id = event.subjectId;
    if (id == null) {
      emit(state.copyWith(loading: false));
      return;
    }
    emit(state.copyWith(loading: true, loadError: null));
    final (subject, semester) = await (_getSubject(id), _getSemester(id)).wait;
    emit(
      subject.fold(
        (s) => state.copyWith(
          loading: false,
          subject: s,
          semester: semester.valueOrNull,
        ),
        (error) => state.copyWith(loading: false, loadError: error),
      ),
    );
  }

  Future<void> _onSubmitted(
    SubjectFormSubmitted event,
    Emitter<SubjectFormState> emit,
  ) async {
    emit(state.copyWith(saving: true, saveError: null));
    final existing = state.subject;
    final saved = existing == null
        ? await _createSubject(event.input)
        : await _updateSubject(
            existing.id,
            event.input,
            clearNextAssessment:
                event.input.nextAssessmentAt == null &&
                existing.nextAssessmentAt != null,
          );
    switch (saved.errorOrNull) {
      case final AppError error:
        emit(state.copyWith(saving: false, saveError: error));
        return;
      case null:
        break;
    }
    final subject = saved.valueOrNull!;
    final semesterError = await _saveSemester(subject.id, event);
    emit(
      state.copyWith(
        saving: false,
        subject: subject,
        saveError: semesterError,
        savedSubjectId: semesterError == null ? subject.id : null,
      ),
    );
  }

  /// Guarda o borra el curso/semestre solo si ha cambiado.
  Future<AppError?> _saveSemester(
    String subjectId,
    SubjectFormSubmitted event,
  ) async {
    final current = state.semester;
    final course = event.course;
    final semester = event.semester;
    if (course != null && semester != null) {
      if (current?.course == course && current?.semester == semester) {
        return null;
      }
      final result = await _assignSemester(
        subjectId,
        course: course,
        semester: semester,
      );
      return result.errorOrNull;
    }
    if (current != null) {
      return (await _clearSemester(subjectId)).errorOrNull;
    }
    return null;
  }
}
