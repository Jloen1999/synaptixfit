import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_due_review.freezed.dart';

/// Material de estudio con repaso espaciado pendiente.
@freezed
abstract class HomeDueReview with _$HomeDueReview {
  const factory HomeDueReview({
    required String id,
    required String title,
    DateTime? nextReviewAt,
  }) = _HomeDueReview;
}
