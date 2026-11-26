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
  }) = _TemplateRunDay;
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
