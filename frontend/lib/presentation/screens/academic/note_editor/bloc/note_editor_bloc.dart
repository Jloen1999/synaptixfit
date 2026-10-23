import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../../domain/use_cases/academic/create_note_use_case.dart';
import '../../../../../domain/use_cases/academic/get_note_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subjects_use_case.dart';
import '../../../../../domain/use_cases/academic/update_note_use_case.dart';

part 'note_editor_bloc.freezed.dart';
part 'note_editor_event.dart';
part 'note_editor_state.dart';

/// Editor de apuntes en Markdown (alta y edición).
class NoteEditorBloc extends Bloc<NoteEditorEvent, NoteEditorState> {
  NoteEditorBloc({
    required this._getNote,
    required this._getSubjects,
    required this._createNote,
    required this._updateNote,
  }) : super(const NoteEditorState()) {
    on<NoteEditorStarted>(_onStarted);
    on<NoteEditorSubmitted>(_onSubmitted);
  }

  final GetNoteUseCaseContract _getNote;
  final GetSubjectsUseCaseContract _getSubjects;
  final CreateNoteUseCaseContract _createNote;
  final UpdateNoteUseCaseContract _updateNote;

  Future<void> _onStarted(
    NoteEditorStarted event,
    Emitter<NoteEditorState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        loadError: null,
        initialSubjectId: event.subjectId,
        initialQuickNote: event.quickNote,
      ),
    );
    final subjects = await _getSubjects(archived: false);
    final noteId = event.noteId;
    if (noteId == null) {
      emit(
        state.copyWith(
          loading: false,
          subjects: subjects.valueOrNull ?? const [],
        ),
      );
      return;
    }
    final note = await _getNote(noteId);
    emit(
      note.fold(
        (n) => state.copyWith(
          loading: false,
          note: n,
          initialSubjectId: n.subjectId,
          initialQuickNote: n.quickNote,
          subjects: subjects.valueOrNull ?? const [],
        ),
        (error) => state.copyWith(loading: false, loadError: error),
      ),
    );
  }

  Future<void> _onSubmitted(
    NoteEditorSubmitted event,
    Emitter<NoteEditorState> emit,
  ) async {
    emit(state.copyWith(saving: true, saveError: null));
    final existing = state.note;
    final result = existing == null
        ? await _createNote(
            subjectId: event.subjectId,
            title: event.title,
            content: event.content,
            visibility: event.visibility,
            quickNote: event.quickNote,
          )
        : await _updateNote(
            existing.id,
            title: event.title,
            content: event.content,
            visibility: event.visibility,
            quickNote: event.quickNote,
            subjectId: event.subjectId,
            detachSubject:
                event.subjectId == null && existing.subjectId != null,
          );
    emit(
      result.fold(
        (n) => state.copyWith(saving: false, note: n, savedNoteId: n.id),
        (error) => state.copyWith(saving: false, saveError: error),
      ),
    );
  }
}
