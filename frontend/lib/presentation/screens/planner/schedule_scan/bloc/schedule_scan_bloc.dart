import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/planner/planner_ai.dart';
import '../../../../../domain/models/planner/planner_options.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/planner/export_ics_use_case.dart';
import '../../../../../domain/use_cases/planner/get_planner_subjects_use_case.dart';
import '../../../../../domain/use_cases/planner/import_ics_use_case.dart';
import '../../../../../domain/use_cases/planner/save_semester_dates_use_case.dart';
import '../../../../../domain/use_cases/planner/scan_schedule_use_case.dart';

part 'schedule_scan_bloc.freezed.dart';
part 'schedule_scan_event.dart';
part 'schedule_scan_state.dart';

/// Importación de horarios: escaneo con IA (PDF/imagen) e ICS, y exportación.
class ScheduleScanBloc extends Bloc<ScheduleScanEvent, ScheduleScanState> {
  ScheduleScanBloc({
    required this._getSubjects,
    required this._scanSchedule,
    required this._saveSemesterDates,
    required this._importIcs,
    required this._exportIcs,
  }) : super(const ScheduleScanState()) {
    on<ScheduleScanStarted>(_onStarted);
    on<ScheduleScanFileSelected>(_onFileSelected);
    on<ScheduleScanSemesterDatesSubmitted>(_onDatesSubmitted);
    on<ScheduleScanSemesterDatesDismissed>(_onDatesDismissed);
    on<ScheduleScanProgressUpdated>(
      (e, emit) => emit(state.copyWith(progress: e.progress.clamp(0, 1))),
    );
    on<ScheduleScanIcsImportRequested>(_onIcsImport);
    on<ScheduleScanExportRequested>(_onExport);
  }

  /// Código de la API cuando el perfil no tiene fechas de semestre.
  static const semesterDatesMissing = 'SCHEDULE_SEMESTER_DATES_MISSING';

  final GetPlannerSubjectsUseCaseContract _getSubjects;
  final ScanScheduleUseCaseContract _scanSchedule;
  final SaveSemesterDatesUseCaseContract _saveSemesterDates;
  final ImportIcsUseCaseContract _importIcs;
  final ExportIcsUseCaseContract _exportIcs;

  ScheduleScanState _notice(ScheduleScanState next, ScheduleScanNotice n) =>
      next.copyWith(notice: n, noticeId: state.noticeId + 1);

  Future<void> _onStarted(
    ScheduleScanStarted event,
    Emitter<ScheduleScanState> emit,
  ) async {
    final result = await _getSubjects();
    emit(
      state.copyWith(
        subjects: result.valueOrNull ?? const [],
        subjectsLoaded: true,
      ),
    );
  }

  Future<void> _onFileSelected(
    ScheduleScanFileSelected event,
    Emitter<ScheduleScanState> emit,
  ) => _scan(event.file, emit);

  Future<void> _scan(ScheduleFile file, Emitter<ScheduleScanState> emit) async {
    if (state.scanStatus == ScanStatus.uploading) return;
    emit(
      state.copyWith(
        scanStatus: ScanStatus.uploading,
        progress: 0,
        pendingFile: file,
        scanResult: null,
        scanError: null,
      ),
    );
    final result = await _scanSchedule(
      file,
      onProgress: (p) {
        if (!isClosed) add(ScheduleScanEvent.progressUpdated(p));
      },
    );
    switch (result) {
      case Failure(:final error)
          when error == const AppError.business(semesterDatesMissing):
        emit(
          _notice(
            state.copyWith(scanStatus: ScanStatus.needsSemesterDates),
            const ScheduleScanNotice.askSemesterDates(),
          ),
        );
      case Failure(:final error):
        emit(
          state.copyWith(
            scanStatus: ScanStatus.idle,
            pendingFile: null,
            scanError: error,
          ),
        );
      case Success(:final value):
        emit(
          _notice(
            state.copyWith(
              scanStatus: ScanStatus.done,
              progress: 1,
              pendingFile: null,
              scanResult: value,
            ),
            ScheduleScanNotice.scanned(value),
          ),
        );
    }
  }

  Future<void> _onDatesSubmitted(
    ScheduleScanSemesterDatesSubmitted event,
    Emitter<ScheduleScanState> emit,
  ) async {
    emit(state.copyWith(scanStatus: ScanStatus.savingDates));
    final saved = await _saveSemesterDates(start: event.start, end: event.end);
    if (saved case Failure(:final error)) {
      emit(
        _notice(
          state.copyWith(scanStatus: ScanStatus.needsSemesterDates),
          ScheduleScanNotice.failure(error),
        ),
      );
      return;
    }
    final file = state.pendingFile;
    if (file == null) {
      emit(state.copyWith(scanStatus: ScanStatus.idle));
      return;
    }
    emit(state.copyWith(scanStatus: ScanStatus.idle));
    await _scan(file, emit);
  }

  void _onDatesDismissed(
    ScheduleScanSemesterDatesDismissed event,
    Emitter<ScheduleScanState> emit,
  ) {
    emit(state.copyWith(scanStatus: ScanStatus.idle, pendingFile: null));
  }

  Future<void> _onIcsImport(
    ScheduleScanIcsImportRequested event,
    Emitter<ScheduleScanState> emit,
  ) async {
    if (state.importingIcs) return;
    emit(
      state.copyWith(
        importingIcs: true,
        icsResult: null,
        icsSubjectId: event.subjectId,
        icsUrl: event.url,
      ),
    );
    final result = await _importIcs(
      subjectId: event.subjectId,
      url: event.url,
      force: event.force,
    );
    switch (result) {
      case Failure(:final error):
        emit(
          _notice(
            state.copyWith(importingIcs: false),
            ScheduleScanNotice.failure(error),
          ),
        );
      case Success(:final value):
        emit(
          _notice(
            state.copyWith(importingIcs: false, icsResult: value),
            ScheduleScanNotice.icsImported(value),
          ),
        );
    }
  }

  Future<void> _onExport(
    ScheduleScanExportRequested event,
    Emitter<ScheduleScanState> emit,
  ) async {
    if (state.exporting) return;
    emit(state.copyWith(exporting: true));
    final result = await _exportIcs();
    emit(
      _notice(
        state.copyWith(exporting: false),
        result.fold(ScheduleScanNotice.exportReady, ScheduleScanNotice.failure),
      ),
    );
  }
}
