part of 'routine_editor_bloc.dart';

/// Pasos del asistente: parámetros (solo IA) → generando → edición.
enum EditorStep { parameters, generating, editing }

@freezed
abstract class RoutineEditorState with _$RoutineEditorState {
  const factory RoutineEditorState({
    @Default(EditorStep.parameters) EditorStep step,

    /// `false` si se crea desde cero.
    @Default(true) bool aiMode,
    @Default(4) int weeksParam,
    TrainingGoal? goalParam,
    @Default(RoutineDraft()) RoutineDraft draft,

    /// Metadatos de la última propuesta (IA o motor de reglas).
    RoutineProposal? proposal,
    @Default(false) bool refining,
    @Default(false) bool saving,

    /// Se ha intentado guardar con datos inválidos: la página marca los errores.
    @Default(false) bool showValidation,
    TrainingEffect? effect,
  }) = _RoutineEditorState;

  const RoutineEditorState._();

  static const minNameLength = 3;

  bool get nameValid => draft.name.trim().length >= minNameLength;

  bool get canSave => nameValid && draft.weeks.isNotEmpty;

  bool get busy => refining || saving || step == EditorStep.generating;
}
