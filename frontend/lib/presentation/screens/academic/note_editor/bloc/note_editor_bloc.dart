import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../../domain/models/academic/note_draft.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../../domain/use_cases/academic/create_note_use_case.dart';
import '../../../../../domain/use_cases/academic/discard_note_draft_use_case.dart';
import '../../../../../domain/use_cases/academic/get_note_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subjects_use_case.dart';
import '../../../../../domain/use_cases/academic/load_note_draft_use_case.dart';
import '../../../../../domain/use_cases/academic/save_note_draft_use_case.dart';
import '../../../../../domain/use_cases/academic/update_note_use_case.dart';

part 'note_editor_bloc.freezed.dart';
part 'note_editor_event.dart';
part 'note_editor_state.dart';

/// Editor de apuntes en Markdown (alta y edición). Mientras se escribe guarda
/// un borrador en el teléfono; si la app se cerró sin guardar, al volver lo
/// ofrece. Se borra al guardar o al descartar.
class NoteEditorBloc extends Bloc<NoteEditorEvent, NoteEditorState> {
  NoteEditorBloc({
    required this._getNote,
    required this._getSubjects,
    required this._createNote,
    required this._updateNote,
    required this._loadDraft,
    required this._saveDraft,
    required this._discardDraft,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const NoteEditorState()) {
    on<NoteEditorStarted>(_onStarted);
    on<NoteEditorSubmitted>(_onSubmitted);
    on<NoteEditorDraftChanged>(_onDraftChanged);
    on<NoteEditorDraftRestored>(
      (_, emit) => emit(state.copyWith(recoverableDraft: null)),
    );
    on<NoteEditorDraftDiscarded>((_, emit) async {
      emit(state.copyWith(recoverableDraft: null));
      await _discard();
    });
    on<NoteEditorProfilePrivacyChanged>(
      (event, emit) => emit(state.copyWith(profilePrivacy: event.privacy)),
    );
  }

  final GetNoteUseCaseContract _getNote;
  final GetSubjectsUseCaseContract _getSubjects;
  final CreateNoteUseCaseContract _createNote;
  final UpdateNoteUseCaseContract _updateNote;
  final LoadNoteDraftUseCaseContract _loadDraft;
  final SaveNoteDraftUseCaseContract _saveDraft;
  final DiscardNoteDraftUseCaseContract _discardDraft;
  final DateTime Function() _now;

  /// Cuenta y apunte del borrador (llegan en `started`).
  String _accountId = '';
  String? _noteId;

  /// Sin cuenta no se guarda nada: el borrador quedaría sin dueño.
  bool get _draftsEnabled => _accountId.isNotEmpty;

  Future<void> _discard() async {
    if (!_draftsEnabled) return;
    await _discardDraft(accountId: _accountId, noteId: _noteId);
  }

  /// Un borrador vacío no se guarda: se borra el que hubiera.
  Future<void> _onDraftChanged(
    NoteEditorDraftChanged event,
    Emitter<NoteEditorState> emit,
  ) async {
    if (!_draftsEnabled || state.savedNoteId != null) return;
    final draft = NoteDraft(
      accountId: _accountId,
      noteId: _noteId,
      title: event.title,
      content: event.content,
      visibility: event.visibility,
      quickNote: event.quickNote,
      subjectId: event.subjectId,
      savedAt: _now(),
    );
    if (draft.isEmpty) {
      await _discard();
    } else {
      await _saveDraft(draft);
    }
  }

  /// El borrador se ofrece solo si dice algo distinto de lo guardado.
  Future<NoteDraft?> _pendingDraft(Note? note) async {
    if (!_draftsEnabled) return null;
    final draft = (await _loadDraft(
      accountId: _accountId,
      noteId: _noteId,
    )).valueOrNull;
    if (draft == null || draft.isEmpty) return null;
    final same =
        note != null &&
        note.title == draft.title &&
        note.content == draft.content;
    return same ? null : draft;
  }

  Future<void> _onStarted(
    NoteEditorStarted event,
    Emitter<NoteEditorState> emit,
  ) async {
    _accountId = event.accountId;
    _noteId = event.noteId;
    emit(
      state.copyWith(
        loading: true,
        loadError: null,
        initialSubjectId: event.subjectId,
        initialQuickNote: event.quickNote,
        profilePrivacy: event.profilePrivacy,
      ),
    );
    final subjects = await _getSubjects(archived: false);
    final noteId = event.noteId;
    if (noteId == null) {
      final draft = await _pendingDraft(null);
      emit(
        state.copyWith(
          loading: false,
          subjects: subjects.valueOrNull ?? const [],
          recoverableDraft: draft,
        ),
      );
      return;
    }
    final note = await _getNote(noteId);
    final loaded = note.valueOrNull;
    final draft = loaded == null ? null : await _pendingDraft(loaded);
    emit(
      note.fold(
        (n) => state.copyWith(
          loading: false,
          note: n,
          initialVisibility: state.allowed(n.visibility),
          initialSubjectId: n.subjectId,
          initialQuickNote: n.quickNote,
          subjects: subjects.valueOrNull ?? const [],
          recoverableDraft: draft,
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
    // Guardado en el servidor: el borrador ya no hace falta.
    if (result.valueOrNull != null) await _discard();
    emit(
      result.fold(
        (n) => state.copyWith(saving: false, note: n, savedNoteId: n.id),
        (error) => state.copyWith(saving: false, saveError: error),
      ),
    );
  }
}
