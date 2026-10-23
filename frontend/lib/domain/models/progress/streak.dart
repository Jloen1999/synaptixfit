import 'package:freezed_annotation/freezed_annotation.dart';

part 'streak.freezed.dart';

/// Racha diaria de actividad del usuario.
@freezed
abstract class Streak with _$Streak {
  const factory Streak({
    required int currentDays,
    required int bestDays,
    required bool activeToday,

    /// La racha se pierde si hoy no hay actividad.
    required bool atRisk,

    /// Siguiente hito (7, 30, 100 o 365); nulo si ya se superaron todos.
    int? nextMilestone,
    required int daysToNextMilestone,

    /// Progreso hacia el siguiente hito entre 0 y 1.
    required double milestoneProgress,
    @Default(<int>[]) List<int> reachedMilestones,
  }) = _Streak;

  /// Hitos de racha que la app celebra.
  static const milestones = [7, 30, 100, 365];
}
