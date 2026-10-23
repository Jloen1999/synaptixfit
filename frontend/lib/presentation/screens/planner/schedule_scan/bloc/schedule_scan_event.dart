part of 'schedule_scan_bloc.dart';

@freezed
sealed class ScheduleScanEvent with _$ScheduleScanEvent {
  /// Carga las asignaturas (para la importación ICS).
  const factory ScheduleScanEvent.started() = ScheduleScanStarted;

  /// Archivo elegido: se sube y se escanea.
  const factory ScheduleScanEvent.fileSelected(ScheduleFile file) =
      ScheduleScanFileSelected;

  /// Fechas del semestre indicadas: se guardan y se reintenta el escaneo.
  const factory ScheduleScanEvent.semesterDatesSubmitted({
    required DateTime start,
    required DateTime end,
  }) = ScheduleScanSemesterDatesSubmitted;

  const factory ScheduleScanEvent.semesterDatesDismissed() =
      ScheduleScanSemesterDatesDismissed;

  const factory ScheduleScanEvent.progressUpdated(double progress) =
      ScheduleScanProgressUpdated;

  const factory ScheduleScanEvent.icsImportRequested({
    required String subjectId,
    String? url,
    @Default(false) bool force,
  }) = ScheduleScanIcsImportRequested;

  const factory ScheduleScanEvent.exportRequested() =
      ScheduleScanExportRequested;
}
