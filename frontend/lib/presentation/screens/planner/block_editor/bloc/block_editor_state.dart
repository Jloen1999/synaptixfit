part of 'block_editor_bloc.dart';

enum BlockEditorStatus { loading, ready }

/// Problemas de validación que se detectan antes de llamar a la API.
/// [nameMissing]: un evento personal necesita nombre (lo exige también el
/// servidor, que lo guarda en los temas).
enum BlockEditorIssue { inPast, tooShort, noWeekdays, nameMissing }

@freezed
abstract class BlockEditorState with _$BlockEditorState {
  const factory BlockEditorState({
    /// Bloque en edición (`null` al crear).
    CalendarBlock? block,
    @Default(BlockEditorStatus.loading) BlockEditorStatus status,
    @Default(<SubjectOption>[]) List<SubjectOption> subjects,
    @Default(<RoutineOption>[]) List<RoutineOption> routines,
    @Default(<ChallengeOption>[]) List<ChallengeOption> challenges,
    @Default(<Deadline>[]) List<Deadline> deadlines,

    /// Fallo al cargar alguno de los catálogos (el formulario sigue disponible).
    AppError? optionsError,
    @Default(false) bool submitting,
    AppError? error,
    BlockEditorIssue? issue,
    @Default(0) int feedbackId,

    /// Resultado final: la página cierra la hoja devolviéndolo.
    BlockEditorOutcome? outcome,
  }) = _BlockEditorState;

  const BlockEditorState._();

  bool get isEditing => block != null;

  /// Falta el nombre del evento personal: lo detecta la hoja antes de enviar
  /// o lo devuelve el servidor como error del campo `topics`.
  bool get nameMissing =>
      issue == BlockEditorIssue.nameMissing ||
      switch (error) {
        ValidationError(:final fields) => fields.any(
          (f) => f.field == 'topics',
        ),
        _ => false,
      };
}

/// Lo que ha pasado en la hoja; el calendario recarga y lo comunica.
@freezed
sealed class BlockEditorOutcome with _$BlockEditorOutcome {
  const factory BlockEditorOutcome.created({
    required int overlaps,
    @Default(0) int weeklyCopies,
  }) = BlockEditorCreated;

  const factory BlockEditorOutcome.updated() = BlockEditorUpdated;

  /// El usuario quiere borrar el bloque: lo borra el calendario, que permite
  /// deshacerlo unos segundos.
  const factory BlockEditorOutcome.deleteRequested(CalendarBlock block) =
      BlockEditorDeleteRequested;

  const factory BlockEditorOutcome.distributed(int count) =
      BlockEditorDistributed;

  /// El usuario quiere concentrarse en este bloque ahora (abre el Pomodoro).
  const factory BlockEditorOutcome.focusRequested(CalendarBlock block) =
      BlockEditorFocusRequested;

  /// El usuario quiere llevar el bloque no hecho al primer hueco libre.
  const factory BlockEditorOutcome.rescheduleRequested(String blockId) =
      BlockEditorRescheduleRequested;

  /// El usuario pide marcar/desmarcar el bloque (lo resuelve el calendario).
  const factory BlockEditorOutcome.completionRequested(String blockId) =
      BlockEditorCompletionRequested;

  /// «No fui» a una clase: se desmarca y no se da por asistida sola.
  const factory BlockEditorOutcome.absenceRequested(String blockId) =
      BlockEditorAbsenceRequested;

  /// Bloque de un día de rutina: se abre la rutina para entrenarlo (su estado
  /// lo marca la sesión, no la persona).
  const factory BlockEditorOutcome.trainingRequested(String routineId) =
      BlockEditorTrainingRequested;
}
