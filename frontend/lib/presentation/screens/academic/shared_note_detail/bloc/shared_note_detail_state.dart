part of 'shared_note_detail_bloc.dart';

@freezed
abstract class SharedNoteDetailState with _$SharedNoteDetailState {
  const factory SharedNoteDetailState({
    @Default('') String noteId,
    @Default(true) bool loading,
    AppError? error,
    SharedNote? note,
    @Default(false) bool copying,

    /// Id de la copia recién guardada (aviso de una vez).
    String? copiedNoteId,

    /// Error al copiar (el apunte sigue a la vista).
    AppError? copyError,
  }) = _SharedNoteDetailState;
}
