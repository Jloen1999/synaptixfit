part of 'block_editor_bloc.dart';

@freezed
sealed class BlockEditorEvent with _$BlockEditorEvent {
  /// Carga asignaturas, rutinas, retos y entregas pendientes.
  const factory BlockEditorEvent.started() = BlockEditorStarted;

  /// Crea el bloque o guarda los cambios del bloque en edición.
  const factory BlockEditorEvent.saveRequested(BlockDraft draft) =
      BlockEditorSaveRequested;

  /// Reparte una rutina completa en el calendario.
  const factory BlockEditorEvent.distributionRequested(
    RoutineDistribution request,
  ) = BlockEditorDistributionRequested;
}
