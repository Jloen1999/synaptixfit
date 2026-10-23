import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/teaching_guide_import_status.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/subject_file.dart';
import '../../../../../domain/models/academic/teaching_guide_import.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/academic/apply_teaching_guide_import_use_case.dart';
import '../../../../../domain/use_cases/academic/await_teaching_guide_import_use_case.dart';
import '../../../../../domain/use_cases/academic/discard_teaching_guide_import_use_case.dart';
import '../../../../../domain/use_cases/academic/retry_teaching_guide_import_use_case.dart';
import '../../../../../domain/use_cases/academic/start_teaching_guide_import_use_case.dart';

part 'teaching_guide_import_bloc.freezed.dart';
part 'teaching_guide_import_event.dart';
part 'teaching_guide_import_state.dart';

/// Asistente «Importar plan docente»: sube el PDF, espera el análisis de la IA
/// (lo hace el servidor), deja revisar el borrador y lo aplica.
class TeachingGuideImportBloc
    extends Bloc<TeachingGuideImportEvent, TeachingGuideImportState> {
  TeachingGuideImportBloc({
    required this._start,
    required this._await,
    required this._retry,
    required this._apply,
    required this._discard,
  }) : super(const TeachingGuideImportState()) {
    on<TeachingGuideImportStarted>(
      (event, emit) => emit(
        TeachingGuideImportState(targetSubjectId: event.targetSubjectId),
      ),
    );
    on<TeachingGuideImportFilePicked>(_onFilePicked);
    on<TeachingGuideImportRetried>(_onRetried);
    on<TeachingGuideImportRestarted>(_onRestarted);
    on<TeachingGuideImportDraftChanged>(
      (event, emit) => emit(state.copyWith(draft: event.draft)),
    );
    on<TeachingGuideImportDestinationChanged>(
      (event, emit) =>
          emit(state.copyWith(destinationSubjectId: event.subjectId)),
    );
    on<TeachingGuideImportCreateDeadlinesChanged>(
      (event, emit) => emit(state.copyWith(createDeadlines: event.value)),
    );
    on<TeachingGuideImportApplied>(_onApplied);
  }

  final StartTeachingGuideImportUseCaseContract _start;
  final AwaitTeachingGuideImportUseCaseContract _await;
  final RetryTeachingGuideImportUseCaseContract _retry;
  final ApplyTeachingGuideImportUseCaseContract _apply;
  final DiscardTeachingGuideImportUseCaseContract _discard;

  Future<void> _onFilePicked(
    TeachingGuideImportFilePicked event,
    Emitter<TeachingGuideImportState> emit,
  ) async {
    emit(
      state.copyWith(
        phase: GuideImportPhase.uploading,
        fileName: event.payload.fileName,
        uploadProgress: 0,
        error: null,
        actionError: null,
      ),
    );
    final started = await _start(
      event.payload,
      targetSubjectId: state.targetSubjectId,
      onProgress: (p) {
        if (!emit.isDone) emit(state.copyWith(uploadProgress: p));
      },
    );
    switch (started) {
      case Success(:final value):
        await _wait(value, emit);
      case Failure(:final error):
        emit(state.copyWith(phase: GuideImportPhase.failed, error: error));
    }
  }

  Future<void> _onRetried(
    TeachingGuideImportRetried event,
    Emitter<TeachingGuideImportState> emit,
  ) async {
    final current = state.guideImport;
    if (current == null) return;
    if (state.waitingWasInterrupted) {
      emit(state.copyWith(error: null));
      await _wait(current, emit);
      return;
    }
    emit(state.copyWith(phase: GuideImportPhase.analyzing, error: null));
    final retried = await _retry(current.id);
    switch (retried) {
      case Success(:final value):
        await _wait(value, emit);
      case Failure(:final error):
        emit(state.copyWith(phase: GuideImportPhase.failed, error: error));
    }
  }

  /// Consulta el análisis hasta que acaba; con el borrador listo, propone
  /// completar la asignatura de origen o la que coincide con el plan.
  Future<void> _wait(
    TeachingGuideImport started,
    Emitter<TeachingGuideImportState> emit,
  ) async {
    emit(
      state.copyWith(phase: GuideImportPhase.analyzing, guideImport: started),
    );
    await emit.forEach<AppResult<TeachingGuideImport>>(
      _await(started.id),
      onData: (result) => switch (result) {
        Success(:final value) => _fromImport(value),
        Failure(:final error) => state.copyWith(
          phase: GuideImportPhase.failed,
          error: error,
        ),
      },
    );
  }

  TeachingGuideImportState _fromImport(TeachingGuideImport i) =>
      switch (i.status) {
        TeachingGuideImportStatus.ready when i.draft != null => state.copyWith(
          phase: GuideImportPhase.review,
          guideImport: i,
          draft: i.draft,
          destinationSubjectId: i.targetSubjectId ?? i.suggestedSubjectId,
        ),
        TeachingGuideImportStatus.failed ||
        TeachingGuideImportStatus.ready => state.copyWith(
          phase: GuideImportPhase.failed,
          guideImport: i,
          error: AppError.business(i.errorCode ?? 'AI_UNAVAILABLE'),
        ),
        _ => state.copyWith(guideImport: i),
      };

  Future<void> _onRestarted(
    TeachingGuideImportRestarted event,
    Emitter<TeachingGuideImportState> emit,
  ) async {
    final current = state.guideImport;
    emit(TeachingGuideImportState(targetSubjectId: state.targetSubjectId));
    // Si el descarte falla no se avisa: el PDF huérfano solo ocupa sitio.
    if (current != null) await _discard(current.id);
  }

  Future<void> _onApplied(
    TeachingGuideImportApplied event,
    Emitter<TeachingGuideImportState> emit,
  ) async {
    final current = state.guideImport;
    final draft = state.draft;
    // Un segundo toque mientras se guarda no hace nada (el servidor también lo rechazaría).
    if (current == null || draft == null) return;
    if (state.phase == GuideImportPhase.applying) return;
    emit(state.copyWith(phase: GuideImportPhase.applying, actionError: null));
    final result = await _apply(
      current.id,
      subjectId: state.destinationSubjectId,
      draft: draft,
      createDeadlines: state.createDeadlines,
    );
    emit(
      result.fold(
        (r) => state.copyWith(phase: GuideImportPhase.done, result: r),
        (error) =>
            state.copyWith(phase: GuideImportPhase.review, actionError: error),
      ),
    );
  }
}
