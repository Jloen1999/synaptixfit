part of 'enrollment_import_bloc.dart';

@freezed
sealed class EnrollmentImportEvent with _$EnrollmentImportEvent {
  /// Marca o desmarca el permiso para leer el documento.
  const factory EnrollmentImportEvent.consentChanged(bool value) =
      EnrollmentImportConsentChanged;

  const factory EnrollmentImportEvent.fileChosen(FileUploadPayload file) =
      EnrollmentImportFileChosen;

  /// Elige o quita una asignatura de la propuesta (por su posición).
  const factory EnrollmentImportEvent.subjectToggled(int index) =
      EnrollmentImportSubjectToggled;

  /// Elige todas las que aún no tiene o, si ya lo están, las quita todas.
  const factory EnrollmentImportEvent.allToggled() = EnrollmentImportAllToggled;

  const factory EnrollmentImportEvent.applyRequested() =
      EnrollmentImportApplyRequested;

  /// Volver a empezar con otro documento.
  const factory EnrollmentImportEvent.restarted() = EnrollmentImportRestarted;
}
