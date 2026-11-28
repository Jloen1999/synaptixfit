part of 'wod_editor_bloc.dart';

/// Cómo acabó el editor: la página sale y avisa.
enum WodEditorOutcome { saved, deleted }

@freezed
abstract class WodEditorState with _$WodEditorState {
  const factory WodEditorState({
    @Default(false) bool saving,
    @Default(false) bool deleting,
    WodEditorOutcome? outcome,
    AppError? error,
  }) = _WodEditorState;

  const WodEditorState._();

  bool get busy => saving || deleting;
}
