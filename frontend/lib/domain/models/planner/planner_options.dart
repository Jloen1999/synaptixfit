import 'package:freezed_annotation/freezed_annotation.dart';

part 'planner_options.freezed.dart';

/// Asignatura que se puede asociar a un bloque o entrega.
@freezed
abstract class SubjectOption with _$SubjectOption {
  const factory SubjectOption({
    required String id,
    required String name,
    String? code,
    String? icsUrl,
  }) = _SubjectOption;

  const SubjectOption._();

  bool get hasIcsUrl => icsUrl != null && icsUrl!.isNotEmpty;
}

/// Rutina que se puede distribuir o vincular.
@freezed
abstract class RoutineOption with _$RoutineOption {
  const factory RoutineOption({required String id, required String name}) =
      _RoutineOption;
}

/// Reto que se puede vincular a un bloque, con sus tareas: un bloque asignado
/// a una tarea la hace avanzar al completarse (ADR 0028).
@freezed
abstract class ChallengeOption with _$ChallengeOption {
  const factory ChallengeOption({
    required String id,
    required String title,
    @Default(<ChallengeTaskOption>[]) List<ChallengeTaskOption> tasks,
  }) = _ChallengeOption;
}

/// Tarea de un reto a la que se puede asignar un bloque.
@freezed
abstract class ChallengeTaskOption with _$ChallengeTaskOption {
  const factory ChallengeTaskOption({
    required String id,
    required String title,
    @Default(false) bool completed,

    /// Vinculada a una entrega o examen: la completa esa entrega y los bloques
    /// son solo tiempo de estudio.
    @Default(false) bool hasDeadline,
  }) = _ChallengeTaskOption;
}
