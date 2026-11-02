import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/mastery_state.dart';
import '../../enums/study_source_type.dart';

part 'study_material.freezed.dart';

/// Apunte o archivo registrado en el repaso espaciado (SM-2).
@freezed
abstract class StudyMaterial with _$StudyMaterial {
  const factory StudyMaterial({
    required String id,
    String? subjectId,
    required StudySourceType originType,
    required String originId,
    required String title,
    required MasteryState masteryState,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    required int intervalDays,
    required double easeFactor,
    required int completedReviews,
    required int failedReviews,
    DateTime? createdAt,
  }) = _StudyMaterial;

  const StudyMaterial._();

  /// Toca repasarlo (o nunca se ha repasado).
  bool isDueAt(DateTime now) =>
      nextReviewAt == null || !nextReviewAt!.isAfter(now);
}

/// Intervalos posibles según la autoevaluación (0-5).
@freezed
abstract class ReviewPreview with _$ReviewPreview {
  const factory ReviewPreview({
    required double loadToday,
    required double maxDailyLoad,
    required double fatigueCoefficient,
    @Default(<ReviewOption>[]) List<ReviewOption> options,

    /// Práctica reciente con preguntas y la nota que propone el servidor con
    /// ella (nula si no se practicó hace poco).
    PracticeScore? practice,
  }) = _ReviewPreview;

  const ReviewPreview._();

  /// Todas las opciones llevan al mismo intervalo (p. ej. tras un fallo, SM-2
  /// empieza de nuevo y tanto fallar como acertar vuelve en 1 día).
  bool get sameIntervalForAll =>
      options.length > 1 &&
      options.every((o) => o.intervalDays == options.first.intervalDays);
}

/// Aciertos de la práctica reciente y nota de autoevaluación propuesta.
@freezed
abstract class PracticeScore with _$PracticeScore {
  const factory PracticeScore({
    required int correct,
    required int answered,
    required int suggestedQuality,
  }) = _PracticeScore;
}

/// Resultado previsto de una autoevaluación concreta.
@freezed
abstract class ReviewOption with _$ReviewOption {
  const factory ReviewOption({
    required int quality,
    required double adjustedQuality,
    required int intervalDays,
    DateTime? nextReviewAt,
    required MasteryState resultingState,
  }) = _ReviewOption;
}

/// Repaso registrado.
@freezed
abstract class ReviewRecord with _$ReviewRecord {
  const factory ReviewRecord({
    required String id,
    required DateTime reviewedAt,
    required int realQuality,
    required double adjustedQuality,
    required double fatigueCoefficient,
  }) = _ReviewRecord;
}

/// Material actualizado tras un repaso.
@freezed
abstract class ReviewOutcome with _$ReviewOutcome {
  const factory ReviewOutcome({
    required StudyMaterial material,
    ReviewRecord? review,

    /// XP concedida: solo los repasos que tocaban (vencidos o el primero) la dan.
    @Default(0) int xpAwarded,
  }) = _ReviewOutcome;
}
