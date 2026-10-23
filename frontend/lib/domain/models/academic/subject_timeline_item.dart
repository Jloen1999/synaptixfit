import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/subject_timeline_type.dart';

part 'subject_timeline_item.freezed.dart';

/// Elemento de la línea de tiempo de una asignatura (bloque o entrega).
@freezed
abstract class SubjectTimelineItem with _$SubjectTimelineItem {
  const factory SubjectTimelineItem({
    required String id,
    required SubjectTimelineType type,
    required bool isDeadline,
    required String title,
    required DateTime start,
    DateTime? end,
    required bool completed,
    String? location,
  }) = _SubjectTimelineItem;
}
