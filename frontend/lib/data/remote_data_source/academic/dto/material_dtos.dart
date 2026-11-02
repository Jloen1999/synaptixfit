import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/mastery_state.dart';
import '../../../../domain/enums/study_source_type.dart';
import '../../../../domain/models/academic/study_material.dart';

part 'material_dtos.freezed.dart';
part 'material_dtos.g.dart';

@freezed
abstract class StudyMaterialDto with _$StudyMaterialDto {
  const factory StudyMaterialDto({
    required String id,
    String? subjectId,
    String? originType,
    required String originId,
    @Default('') String title,
    String? masteryState,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    @Default(0) int intervalDays,
    @Default(2.5) double easeFactor,
    @Default(0) int completedReviews,
    @Default(0) int failedReviews,
    DateTime? createdAt,
  }) = _StudyMaterialDto;

  const StudyMaterialDto._();

  factory StudyMaterialDto.fromJson(Map<String, dynamic> json) =>
      _$StudyMaterialDtoFromJson(json);

  StudyMaterial toDomain() => StudyMaterial(
    id: id,
    subjectId: subjectId,
    originType: StudySourceType.fromApi(originType),
    originId: originId,
    title: title,
    masteryState: MasteryState.fromApi(masteryState),
    lastReviewedAt: lastReviewedAt?.toLocal(),
    nextReviewAt: nextReviewAt?.toLocal(),
    intervalDays: intervalDays,
    easeFactor: easeFactor,
    completedReviews: completedReviews,
    failedReviews: failedReviews,
    createdAt: createdAt?.toLocal(),
  );
}

@freezed
abstract class ReviewOptionDto with _$ReviewOptionDto {
  const factory ReviewOptionDto({
    required int quality,
    @Default(0) double adjustedQuality,
    @Default(0) int intervalDays,
    DateTime? nextReviewAt,
    String? resultingState,
  }) = _ReviewOptionDto;

  const ReviewOptionDto._();

  factory ReviewOptionDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewOptionDtoFromJson(json);

  ReviewOption toDomain() => ReviewOption(
    quality: quality,
    adjustedQuality: adjustedQuality,
    intervalDays: intervalDays,
    nextReviewAt: nextReviewAt?.toLocal(),
    resultingState: MasteryState.fromApi(resultingState),
  );
}

@freezed
abstract class ReviewPreviewDto with _$ReviewPreviewDto {
  const factory ReviewPreviewDto({
    @Default(0) double loadToday,
    @Default(0) double maxDailyLoad,
    @Default(0) double fatigueCoefficient,
    @Default(<ReviewOptionDto>[]) List<ReviewOptionDto> options,
    PracticeScoreDto? practice,
  }) = _ReviewPreviewDto;

  const ReviewPreviewDto._();

  factory ReviewPreviewDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewPreviewDtoFromJson(json);

  /// Opciones ordenadas de 0 a 5.
  ReviewPreview toDomain() => ReviewPreview(
    loadToday: loadToday,
    maxDailyLoad: maxDailyLoad,
    fatigueCoefficient: fatigueCoefficient,
    options: (options.map((o) => o.toDomain()).toList()
      ..sort((a, b) => a.quality.compareTo(b.quality))),
    practice: practice?.toDomain(),
  );
}

@freezed
abstract class PracticeScoreDto with _$PracticeScoreDto {
  const factory PracticeScoreDto({
    @Default(0) int correct,
    @Default(0) int answered,
    @Default(0) int suggestedQuality,
  }) = _PracticeScoreDto;

  const PracticeScoreDto._();

  factory PracticeScoreDto.fromJson(Map<String, dynamic> json) =>
      _$PracticeScoreDtoFromJson(json);

  PracticeScore toDomain() => PracticeScore(
    correct: correct,
    answered: answered,
    suggestedQuality: suggestedQuality.clamp(0, 5),
  );
}

@freezed
abstract class ReviewRecordDto with _$ReviewRecordDto {
  const factory ReviewRecordDto({
    required String id,
    required DateTime reviewedAt,
    @Default(0) int realQuality,
    @Default(0) double adjustedQuality,
    @Default(0) double fatigueCoefficient,
  }) = _ReviewRecordDto;

  const ReviewRecordDto._();

  factory ReviewRecordDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewRecordDtoFromJson(json);

  ReviewRecord toDomain() => ReviewRecord(
    id: id,
    reviewedAt: reviewedAt.toLocal(),
    realQuality: realQuality,
    adjustedQuality: adjustedQuality,
    fatigueCoefficient: fatigueCoefficient,
  );
}

@freezed
abstract class ReviewResponseDto with _$ReviewResponseDto {
  const factory ReviewResponseDto({
    required StudyMaterialDto material,
    ReviewRecordDto? review,
    @Default(0) int xpAwarded,
  }) = _ReviewResponseDto;

  const ReviewResponseDto._();

  factory ReviewResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewResponseDtoFromJson(json);

  ReviewOutcome toDomain() => ReviewOutcome(
    material: material.toDomain(),
    review: review?.toDomain(),
    xpAwarded: xpAwarded,
  );
}
