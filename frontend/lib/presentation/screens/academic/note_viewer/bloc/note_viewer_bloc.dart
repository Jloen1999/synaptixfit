import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/study_source_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../../domain/models/academic/study_document.dart';
import '../../../../../domain/use_cases/academic/delete_note_use_case.dart';
import '../../../../../domain/use_cases/academic/get_document_availability_use_case.dart';
import '../../../../../domain/use_cases/academic/get_note_use_case.dart';
import '../../../../../domain/use_cases/academic/register_study_material_use_case.dart';

part 'note_viewer_bloc.freezed.dart';
part 'note_viewer_event.dart';
part 'note_viewer_state.dart';

/// Visor de un apunte con acceso al asistente de IA, repaso y práctica.
class NoteViewerBloc extends Bloc<NoteViewerEvent, NoteViewerState> {
  NoteViewerBloc({
    required this._getNote,
    required this._getAvailability,
    required this._deleteNote,
    required this._registerMaterial,
  }) : super(const NoteViewerState()) {
    on<NoteViewerStarted>((event, emit) async {
      emit(state.copyWith(noteId: event.noteId));
      await _load(emit, silent: false);
    });
    on<NoteViewerRefreshed>((_, emit) => _load(emit, silent: true));
    on<NoteViewerDeleteRequested>(_onDelete);
    on<NoteViewerMaterialRequested>(_onMaterial);
  }

  final GetNoteUseCaseContract _getNote;
  final GetDocumentAvailabilityUseCaseContract _getAvailability;
  final DeleteNoteUseCaseContract _deleteNote;
  final RegisterStudyMaterialUseCaseContract _registerMaterial;

  Future<void> _load(
    Emitter<NoteViewerState> emit, {
    required bool silent,
  }) async {
    if (!silent) emit(state.copyWith(loading: true, error: null));
    final (note, availability) = await (
      _getNote(state.noteId),
      _getAvailability(StudySourceType.note, state.noteId),
    ).wait;
    emit(
      note.fold(
        (n) => state.copyWith(
          loading: false,
          error: null,
          note: n,
          availability: availability.valueOrNull ?? DocumentAvailability.none,
        ),
        (error) => state.copyWith(loading: false, error: error),
      ),
    );
  }

  Future<void> _onDelete(
    NoteViewerDeleteRequested event,
    Emitter<NoteViewerState> emit,
  ) async {
    emit(state.copyWith(busy: true, actionError: null));
    final result = await _deleteNote(state.noteId);
    emit(
      result.fold(
        (_) => state.copyWith(busy: false, deleted: true),
        (error) => state.copyWith(busy: false, actionError: error),
      ),
    );
  }

  Future<void> _onMaterial(
    NoteViewerMaterialRequested event,
    Emitter<NoteViewerState> emit,
  ) async {
    emit(state.copyWith(busy: true, actionError: null, navigation: null));
    final result = await _registerMaterial(StudySourceType.note, state.noteId);
    emit(
      result.fold(
        (m) => state.copyWith(
          busy: false,
          navigation: (materialId: m.id, practice: event.practice),
        ),
        (error) => state.copyWith(busy: false, actionError: error),
      ),
    );
  }
}
