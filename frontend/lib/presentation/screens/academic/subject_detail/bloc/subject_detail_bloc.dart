import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../../domain/use_cases/academic/delete_subject_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subject_semester_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subject_use_case.dart';
import '../../../../../domain/use_cases/academic/set_subject_archived_use_case.dart';

part 'subject_detail_bloc.freezed.dart';
part 'subject_detail_event.dart';
part 'subject_detail_state.dart';

/// Cabecera del detalle de asignatura: datos, archivar y borrar.
class SubjectDetailBloc extends Bloc<SubjectDetailEvent, SubjectDetailState> {
  SubjectDetailBloc({
    required this._getSubject,
    required this._getSemester,
    required this._setArchived,
    required this._deleteSubject,
  }) : super(const SubjectDetailState()) {
    on<SubjectDetailStarted>((event, emit) async {
      emit(state.copyWith(subjectId: event.subjectId));
      await _load(emit, silent: false);
    });
    on<SubjectDetailRefreshed>((_, emit) => _load(emit, silent: true));
    on<SubjectDetailArchiveToggled>(_onArchiveToggled);
    on<SubjectDetailDeleteRequested>(_onDelete);
  }

  final GetSubjectUseCaseContract _getSubject;
  final GetSubjectSemesterUseCaseContract _getSemester;
  final SetSubjectArchivedUseCaseContract _setArchived;
  final DeleteSubjectUseCaseContract _deleteSubject;

  Future<void> _load(
    Emitter<SubjectDetailState> emit, {
    required bool silent,
  }) async {
    if (!silent) emit(state.copyWith(loading: true, error: null));
    final (subject, semester) = await (
      _getSubject(state.subjectId),
      _getSemester(state.subjectId),
    ).wait;
    emit(
      subject.fold(
        (s) => state.copyWith(
          loading: false,
          error: null,
          subject: s,
          semester: semester.valueOrNull,
        ),
        (error) => state.copyWith(loading: false, error: error),
      ),
    );
  }

  Future<void> _onArchiveToggled(
    SubjectDetailArchiveToggled event,
    Emitter<SubjectDetailState> emit,
  ) async {
    final subject = state.subject;
    if (subject == null) return;
    emit(state.copyWith(busy: true, actionError: null));
    final result = await _setArchived(subject.id, !subject.archived);
    emit(
      result.fold(
        (s) => state.copyWith(busy: false, subject: s),
        (error) => state.copyWith(busy: false, actionError: error),
      ),
    );
  }

  Future<void> _onDelete(
    SubjectDetailDeleteRequested event,
    Emitter<SubjectDetailState> emit,
  ) async {
    emit(state.copyWith(busy: true, actionError: null));
    final result = await _deleteSubject(state.subjectId);
    emit(
      result.fold(
        (_) => state.copyWith(busy: false, deleted: true),
        (error) => state.copyWith(busy: false, actionError: error),
      ),
    );
  }
}
