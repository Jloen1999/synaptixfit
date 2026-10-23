import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/challenge_difficulty.dart';
import '../../enums/challenge_type.dart';
import '../../enums/milestone_condition.dart';
import '../../enums/visibility.dart';
import 'challenge.dart';

part 'challenge_draft.freezed.dart';

/// Datos para crear un reto (con tareas opcionales).
@freezed
abstract class ChallengeDraft with _$ChallengeDraft {
  const factory ChallengeDraft({
    required String title,

    /// Sin tipo, el servidor lo deduce de la asignatura.
    ChallengeType? type,
    String? goal,
    @Default(Visibility.private) Visibility visibility,
    @Default(ChallengeDifficulty.medium) ChallengeDifficulty difficulty,

    /// Sin inicio, el reto empieza ahora.
    DateTime? startAt,
    required DateTime endAt,
    String? subjectId,
    ChallengeLink? link,
    @Default(<MilestoneDraft>[]) List<MilestoneDraft> milestones,

    /// Objetivo de sesiones de entrenamiento (solo retos de fitness sin tareas).
    int? sessionTarget,
  }) = _ChallengeDraft;
}

/// Definición de una tarea al crear un reto o reemplazar sus tareas.
@freezed
abstract class MilestoneDraft with _$MilestoneDraft {
  const factory MilestoneDraft({
    /// Tarea existente que se conserva (con su progreso); `null` si es nueva.
    String? id,
    required String title,

    /// Peso porcentual; `null` en todas las tareas reparte 100 a partes iguales.
    double? weight,
    @Default(ChallengeDifficulty.medium) ChallengeDifficulty difficulty,
    String? subjectId,
    String? noteId,
    String? fileId,
    ChallengeLink? link,

    /// Posiciones (base 0) de las tareas de la misma lista de las que depende.
    @Default(<int>[]) List<int> dependsOn,
    @Default(MilestoneCondition.all) MilestoneCondition condition,

    /// Dependencias necesarias con [MilestoneCondition.xOfY].
    int? conditionN,
  }) = _MilestoneDraft;
}

/// Cambios de los datos básicos de un reto. Los campos nulos no cambian.
@freezed
abstract class ChallengeChanges with _$ChallengeChanges {
  const factory ChallengeChanges({
    String? title,
    ChallengeType? type,
    String? goal,
    Visibility? visibility,
    ChallengeDifficulty? difficulty,
    DateTime? startAt,
    DateTime? endAt,
    String? subjectId,
    @Default(false) bool clearSubject,
    ChallengeLink? link,
    @Default(false) bool clearLink,
    int? sessionTarget,

    /// Quita el objetivo de sesiones (el reto deja de contar entrenamientos).
    @Default(false) bool clearSessionTarget,
  }) = _ChallengeChanges;
}
