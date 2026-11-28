part of 'wod_editor_bloc.dart';

@freezed
sealed class WodEditorEvent with _$WodEditorEvent {
  /// Con id cambia mi WOD; sin él lo crea (también partiendo de una plantilla).
  const factory WodEditorEvent.saveRequested(Wod wod) = WodEditorSaveRequested;

  const factory WodEditorEvent.deleteRequested(String wodId) =
      WodEditorDeleteRequested;
}
