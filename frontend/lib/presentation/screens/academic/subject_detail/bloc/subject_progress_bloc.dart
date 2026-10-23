import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/evaluation_mode.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/study_material.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../../domain/models/academic/subject_timeline_item.dart';
import '../../../../../domain/models/academic/teaching_guide.dart';
import '../../../../../domain/use_cases/academic/get_study_materials_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subject_retention_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subject_timeline_use_case.dart';
import '../../../../../domain/use_cases/academic/get_teaching_guide_use_case.dart';
import '../../../../../domain/use_cases/academic/set_assessment_grade_use_case.dart';
import '../../../../../domain/use_cases/academic/set_syllabus_topic_completed_use_case.dart';
import '../../../../../domain/use_cases/academic/set_teaching_guide_mode_use_case.dart';

part 'subject_progress_bloc.freezed.dart';
part 'subject_progress_event.dart';
part 'subject_progress_state.dart';

/// Pestaña Progreso: guía docente (temario, simulador de nota, profesores,
/// bibliografía), retención por estado de dominio y línea de tiempo.
class SubjectProgressBloc
    extends Bloc<SubjectProgressEvent, SubjectProgressState> {
  SubjectProgressBloc({
    required this._getGuide,
    required this._setMode,
    required this._setTopic,
    required this._setGrade,
    required this._getRetention,
    required this._getTimeline,
    required this._getMaterials,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const SubjectProgressState()) {
    on<SubjectProgressStarted>((event, emit) async {
      emit(state.copyWith(subjectId: event.subjectId));
      await _load(emit, silent: false);
    });
    on<SubjectProgressRefreshed>((_, emit) => _load(emit, silent: true));
    on<SubjectProgressModeChanged>(_onModeChanged);
    on<SubjectProgressTopicToggled>(_onTopicToggled);
    on<SubjectProgressGradeChanged>(_onGradeChanged);
  }

  final GetTeachingGuideUseCaseContract _getGuide;
  final SetTeachingGuideModeUseCaseContract _setMode;
  final SetSyllabusTopicCompletedUseCaseContract _setTopic;
  final SetAssessmentGradeUseCaseContract _setGrade;
  final GetSubjectRetentionUseCaseContract _getRetention;
  final GetSubjectTimelineUseCaseContract _getTimeline;
  final GetStudyMaterialsUseCaseContract _getMaterials;
  final DateTime Function() _clock;

  /// Horizonte de la línea de tiempo.
  static const _timelineDays = 90;

  Future<void> _load(
    Emitter<SubjectProgressState> emit, {
    required bool silent,
  }) async {
    if (!silent) emit(state.copyWith(loading: true, error: null));
    final id = state.subjectId;
    final now = _clock();
    final from = DateTime(now.year, now.month, now.day);
    final (guide, retention, timeline, materials) = await (
      _getGuide(id),
      _getRetention(id),
      _getTimeline(
        id,
        from: from,
        to: from.add(const Duration(days: _timelineDays)),
      ),
      _getMaterials(subjectId: id),
    ).wait;
    // La guía es la pieza principal; el resto se degrada sin bloquear.
    emit(
      guide.fold(
        (g) => state.copyWith(
          loading: false,
          error: null,
          guide: g,
          retention: retention.valueOrNull ?? state.retention,
          timeline: timeline.valueOrNull ?? state.timeline,
          materials: materials.valueOrNull ?? state.materials,
        ),
        (error) => state.copyWith(loading: false, error: error),
      ),
    );
  }

  /// La nota estimada y qué criterios cuentan los recalcula el servidor.
  Future<void> _onModeChanged(
    SubjectProgressModeChanged event,
    Emitter<SubjectProgressState> emit,
  ) async {
    if (state.guide?.effectiveMode == event.mode) return;
    emit(state.copyWith(savingGrade: true, actionError: null));
    final result = await _setMode(state.subjectId, event.mode);
    emit(
      result.fold(
        (g) => state.copyWith(savingGrade: false, guide: g),
        (error) => state.copyWith(savingGrade: false, actionError: error),
      ),
    );
  }

  Future<void> _onTopicToggled(
    SubjectProgressTopicToggled event,
    Emitter<SubjectProgressState> emit,
  ) async {
    final guide = state.guide;
    if (guide == null) return;
    // Cambio optimista: se ve marcado al instante y se confirma con el servidor.
    emit(
      state.copyWith(
        actionError: null,
        guide: guide.copyWith(
          topics: [
            for (final t in guide.topics)
              t.index == event.index
                  ? t.copyWith(completed: event.completed)
                  : t,
          ],
        ),
      ),
    );
    final result = await _setTopic(
      state.subjectId,
      event.index,
      event.completed,
    );
    emit(
      result.fold(
        (g) => state.copyWith(guide: g),
        (error) => state.copyWith(guide: guide, actionError: error),
      ),
    );
  }

  Future<void> _onGradeChanged(
    SubjectProgressGradeChanged event,
    Emitter<SubjectProgressState> emit,
  ) async {
    emit(state.copyWith(savingGrade: true, actionError: null));
    final result = await _setGrade(state.subjectId, event.index, event.grade);
    emit(
      result.fold(
        (g) => state.copyWith(savingGrade: false, guide: g),
        (error) => state.copyWith(savingGrade: false, actionError: error),
      ),
    );
  }
}
