import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/planner_enums.dart';

part 'deadline.freezed.dart';

/// Entrega, examen, presentación u otra evaluación.
@freezed
abstract class Deadline with _$Deadline {
  const factory Deadline({
    required String id,
    required String title,
    required DeadlineType type,
    required DateTime dueAt,
    required PlannerPriority difficulty,
    String? description,
    String? subjectId,
    @Default(false) bool completed,
    @Default(false) bool imported,
  }) = _Deadline;
}

/// Página de entregas.
@freezed
abstract class DeadlinePage with _$DeadlinePage {
  const factory DeadlinePage({
    required List<Deadline> items,
    required int page,
    required int totalPages,
  }) = _DeadlinePage;

  const DeadlinePage._();

  bool get hasMore => page + 1 < totalPages;
}

/// Entrega tras marcar/desmarcar y experiencia sumada o restada.
@freezed
abstract class DeadlineCompletion with _$DeadlineCompletion {
  const factory DeadlineCompletion({
    required Deadline deadline,
    required int xpDelta,
  }) = _DeadlineCompletion;
}

/// Datos de una entrega para crearla o editarla.
@freezed
abstract class DeadlineDraft with _$DeadlineDraft {
  const factory DeadlineDraft({
    required String title,
    required DeadlineType type,
    required DateTime dueAt,
    required PlannerPriority difficulty,
    String? description,
    String? subjectId,
  }) = _DeadlineDraft;
}
