import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../../domain/models/academic/study_material.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../../domain/use_cases/academic/get_due_study_materials_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subjects_use_case.dart';
import '../../../../../domain/use_cases/academic/get_unassigned_notes_use_case.dart';
import '../../../../../domain/use_cases/academic/move_note_to_subject_use_case.dart';
import '../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../mixins/data_change_refresh_mixin.dart';

part 'academic_home_bloc.freezed.dart';
part 'academic_home_event.dart';
part 'academic_home_state.dart';

/// Pestaña Académico: asignaturas (activas o archivadas), repasos pendientes y
/// la bandeja de notas sin asignatura. Se refresca sola cuando cambian datos
/// académicos o del planificador.
class AcademicHomeBloc extends Bloc<AcademicHomeEvent, AcademicHomeState>
    with DataChangeRefreshMixin<AcademicHomeEvent, AcademicHomeState> {
  AcademicHomeBloc({
    required this._getSubjects,
    required this._getDue,
    required this._getInbox,
    required this._moveNote,
    required this._watchChanges,
  }) : super(const AcademicHomeState()) {
    on<AcademicHomeStarted>((event, emit) {
      if (event.archived) emit(state.copyWith(showArchived: true));
      watchDataChanges(
        _watchChanges,
        topics: const {DataTopic.academic, DataTopic.planner},
        onChanged: const AcademicHomeEvent.refreshed(),
      );
      return _load(emit);
    });
    on<AcademicHomeRefreshed>((_, emit) => _load(emit, silent: true));
    on<AcademicHomeArchivedToggled>((event, emit) async {
      emit(state.copyWith(showArchived: event.archived));
      await _load(emit);
    });
    on<AcademicHomeNoteMoved>(_onNoteMoved);
    on<AcademicHomeNoticeHandled>(
      (_, emit) => emit(state.copyWith(notice: null)),
    );
  }

  final GetSubjectsUseCaseContract _getSubjects;
  final GetDueStudyMaterialsUseCaseContract _getDue;
  final GetUnassignedNotesUseCaseContract _getInbox;
  final MoveNoteToSubjectUseCaseContract _moveNote;

  Future<void> _onNoteMoved(
    AcademicHomeNoteMoved event,
    Emitter<AcademicHomeState> emit,
  ) async {
    if (state.movingNoteIds.contains(event.noteId)) return;
    emit(state.copyWith(movingNoteIds: {...state.movingNoteIds, event.noteId}));
    final result = await _moveNote(event.noteId, subjectId: event.subjectId);
    final moving = {...state.movingNoteIds}..remove(event.noteId);
    final name = state.subjects
        .where((s) => s.id == event.subjectId)
        .firstOrNull
        ?.name;
    emit(
      result.fold(
        (_) => state.copyWith(
          movingNoteIds: moving,
          inbox: [
            for (final n in state.inbox)
              if (n.id != event.noteId) n,
          ],
          notice: AcademicHomeNotice.noteMoved(name ?? '', event.subjectId),
        ),
        (error) => state.copyWith(
          movingNoteIds: moving,
          notice: AcademicHomeNotice.failed(error),
        ),
      ),
    );
  }

  final WatchDataChangesUseCaseContract _watchChanges;

  Future<void> _load(
    Emitter<AcademicHomeState> emit, {
    bool silent = false,
  }) async {
    if (!silent) emit(state.copyWith(loading: true, error: null));
    final (subjects, due, inbox) = await (
      _getSubjects(archived: state.showArchived),
      _getDue(),
      _getInbox(),
    ).wait;
    emit(
      subjects.fold(
        (list) => state.copyWith(
          loading: false,
          error: null,
          subjects: list,
          // Los repasos pendientes son secundarios: si fallan no bloquean.
          due: due.valueOrNull ?? state.due,
          inbox: inbox.valueOrNull ?? state.inbox,
        ),
        (error) => state.copyWith(loading: false, error: error),
      ),
    );
  }
}
