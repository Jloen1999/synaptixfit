import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../../domain/use_cases/academic/copy_shared_note_use_case.dart';
import '../../../../../domain/use_cases/academic/get_shared_note_use_case.dart';

part 'shared_note_detail_bloc.freezed.dart';
part 'shared_note_detail_event.dart';
part 'shared_note_detail_state.dart';

/// Lectura de un apunte compartido y su copia privada en mis apuntes. Usa
/// [GetSharedNoteUseCaseContract] y [CopySharedNoteUseCaseContract].
class SharedNoteDetailBloc
    extends Bloc<SharedNoteDetailEvent, SharedNoteDetailState> {
  SharedNoteDetailBloc({required this._getNote, required this._copyNote})
    : super(const SharedNoteDetailState()) {
    on<SharedNoteDetailStarted>(_onStarted);
    on<SharedNoteDetailCopyRequested>(_onCopy);
  }

  final GetSharedNoteUseCaseContract _getNote;
  final CopySharedNoteUseCaseContract _copyNote;

  Future<void> _onStarted(
    SharedNoteDetailStarted event,
    Emitter<SharedNoteDetailState> emit,
  ) async {
    emit(SharedNoteDetailState(noteId: event.noteId));
    final result = await _getNote(event.noteId);
    emit(
      result.fold(
        (note) => state.copyWith(loading: false, note: note),
        (error) => state.copyWith(loading: false, error: error),
      ),
    );
  }

  Future<void> _onCopy(
    SharedNoteDetailCopyRequested event,
    Emitter<SharedNoteDetailState> emit,
  ) async {
    // Ya copiado: no se crea otra copia (la página ofrece abrirla).
    if (state.note == null || state.copying || state.copiedNoteId != null) {
      return;
    }
    emit(state.copyWith(copying: true, copyError: null));
    final result = await _copyNote(state.noteId);
    emit(
      result.fold(
        (copy) => state.copyWith(copying: false, copiedNoteId: copy.id),
        (error) => state.copyWith(copying: false, copyError: error),
      ),
    );
  }
}
