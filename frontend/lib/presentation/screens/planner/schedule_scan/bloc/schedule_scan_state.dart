part of 'schedule_scan_bloc.dart';

enum ScanStatus { idle, uploading, needsSemesterDates, savingDates, done }

@freezed
abstract class ScheduleScanState with _$ScheduleScanState {
  const factory ScheduleScanState({
    @Default(<SubjectOption>[]) List<SubjectOption> subjects,
    @Default(false) bool subjectsLoaded,
    @Default(ScanStatus.idle) ScanStatus scanStatus,
    @Default(0) double progress,

    /// Archivo pendiente de escanear (si faltaban las fechas del semestre).
    ScheduleFile? pendingFile,
    ScheduleScanResult? scanResult,
    AppError? scanError,
    @Default(false) bool importingIcs,
    IcsImportResult? icsResult,

    /// Petición ICS del último resultado (para reintentar forzando).
    String? icsSubjectId,
    String? icsUrl,
    @Default(false) bool exporting,
    ScheduleScanNotice? notice,
    @Default(0) int noticeId,
  }) = _ScheduleScanState;
}

@freezed
sealed class ScheduleScanNotice with _$ScheduleScanNotice {
  /// Faltan las fechas del semestre: la página abre la hoja para pedirlas.
  const factory ScheduleScanNotice.askSemesterDates() =
      ScheduleScanNoticeAskDates;

  const factory ScheduleScanNotice.scanned(ScheduleScanResult result) =
      ScheduleScanNoticeScanned;

  const factory ScheduleScanNotice.icsImported(IcsImportResult result) =
      ScheduleScanNoticeIcsImported;

  /// Calendario listo para guardar/compartir.
  const factory ScheduleScanNotice.exportReady(String content) =
      ScheduleScanNoticeExportReady;

  const factory ScheduleScanNotice.failure(AppError error) =
      ScheduleScanNoticeFailure;
}
