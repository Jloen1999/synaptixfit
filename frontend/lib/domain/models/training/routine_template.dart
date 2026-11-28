import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/training_enums.dart';

part 'routine_template.freezed.dart';

/// Día de salir a correr de una plantilla con su entreno de carrera (ADR
/// 0043): al usarla, el servidor lo crea en Entreno › Correr.
@freezed
abstract class TemplateRunDay with _$TemplateRunDay {
  const factory TemplateRunDay({
    required int dayNumber,
    required String workoutCode,

    /// Nombre del entreno de carrera (solo en el detalle de la plantilla).
    String? workoutName,
  }) = _TemplateRunDay;
}

/// Ejercicio de una plantilla en una semana de carga, tal como lo manda el
/// servidor: series, repeticiones o rango, segundos aguantando y descanso.
/// [name] e [imageUrl] son nulos si el ejercicio ya no está en el catálogo.
@freezed
abstract class TemplateExercise with _$TemplateExercise {
  const factory TemplateExercise({
    required String exerciseId,
    String? name,
    String? imageUrl,
    required int sets,
    required int reps,
    int? repMin,
    int? repMax,
    int? repsInReserve,
    int? holdSeconds,
    required int restSeconds,
  }) = _TemplateExercise;

  const TemplateExercise._();

  /// Con rango de repeticiones («8–12 reps»).
  bool get hasRange => holdSeconds == null && repMin != null && repMax != null;
}

/// Día de la plantilla (1 = lunes) con el nombre de su sesión, si tiene, y sus
/// ejercicios en orden.
@freezed
abstract class TemplateDay with _$TemplateDay {
  const factory TemplateDay({
    required int dayNumber,
    String? name,
    @Default(<TemplateExercise>[]) List<TemplateExercise> exercises,
  }) = _TemplateDay;
}

/// Detalle de una plantilla para decidir antes de usarla: sus datos ([summary]),
/// cada día con sus ejercicios y los días de carrera.
@freezed
abstract class RoutineTemplateDetail with _$RoutineTemplateDetail {
  const factory RoutineTemplateDetail({
    required RoutineTemplate summary,
    @Default(<TemplateDay>[]) List<TemplateDay> days,
    @Default(<TemplateRunDay>[]) List<TemplateRunDay> runDays,
  }) = _RoutineTemplateDetail;

  const RoutineTemplateDetail._();

  /// Sin ejercicios ni carreras: no hay nada que enseñar.
  bool get isEmpty =>
      runDays.isEmpty && days.every((d) => d.exercises.isEmpty);
}

/// Plantilla de rutina lista para usar (ADR 0032). Se convierte en una rutina
/// propia con un toque; el servidor decide su contenido y sus semanas.
@freezed
abstract class RoutineTemplate with _$RoutineTemplate {
  const factory RoutineTemplate({
    required String id,
    required String code,
    required String name,
    @Default('') String description,
    TrainingGoal? goal,
    @Default(false) bool atHome,
    @Default(TemplatePlace.gym) TemplatePlace place,
    @Default(TemplateLevel.beginner) TemplateLevel level,

    /// Pensada para semanas de exámenes: sesiones cortas.
    @Default(false) bool forExams,
    required int minutes,
    required int weeks,
    required int daysPerWeek,

    /// Días de gimnasio o casa (1 = lunes).
    @Default(<int>[]) List<int> dayNumbers,

    /// Días de salir a correr (cuentan en [daysPerWeek]).
    @Default(<TemplateRunDay>[]) List<TemplateRunDay> runDays,
    @Default(0) int exerciseCount,

    /// Foto de uno de sus ejercicios para el fondo de la tarjeta (la elige el
    /// servidor; nula si ninguno tiene).
    String? coverImageUrl,
  }) = _RoutineTemplate;

  const RoutineTemplate._();

  /// Lleva carreras: al usarla se crean sus entrenos en Correr.
  bool get hasRuns => runDays.isNotEmpty;
}
