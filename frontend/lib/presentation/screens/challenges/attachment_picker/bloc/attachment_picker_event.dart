part of 'attachment_picker_bloc.dart';

@freezed
sealed class AttachmentPickerEvent with _$AttachmentPickerEvent {
  /// Carga las asignaturas y el material de [subjectId] (o de la primera).
  const factory AttachmentPickerEvent.started({String? subjectId}) =
      AttachmentPickerStarted;

  /// `null` muestra los apuntes sin asignatura.
  const factory AttachmentPickerEvent.subjectChanged(String? subjectId) =
      AttachmentPickerSubjectChanged;
}
