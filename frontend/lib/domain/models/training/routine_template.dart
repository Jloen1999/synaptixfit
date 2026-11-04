import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/training_enums.dart';

part 'routine_template.freezed.dart';

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

    /// Pensada para semanas de exámenes: sesiones cortas.
    @Default(false) bool forExams,
    required int minutes,
    required int weeks,
    required int daysPerWeek,

    /// Días de la semana (1 = lunes).
    @Default(<int>[]) List<int> dayNumbers,
    @Default(0) int exerciseCount,
  }) = _RoutineTemplate;
}
