import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/home/home_due_review.dart';

part 'home_due_review_dto.freezed.dart';
part 'home_due_review_dto.g.dart';

/// Subconjunto de `StudyMaterialResponse` que usa el inicio.
@freezed
abstract class HomeDueReviewDto with _$HomeDueReviewDto {
  const factory HomeDueReviewDto({
    required String id,
    @Default('') String title,
    DateTime? nextReviewAt,
  }) = _HomeDueReviewDto;

  const HomeDueReviewDto._();

  factory HomeDueReviewDto.fromJson(Map<String, dynamic> json) =>
      _$HomeDueReviewDtoFromJson(json);

  HomeDueReview toDomain() => HomeDueReview(
    id: id,
    title: title,
    nextReviewAt: nextReviewAt?.toLocal(),
  );
}
