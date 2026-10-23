import 'package:freezed_annotation/freezed_annotation.dart';

part 'training_volume.freezed.dart';

/// Volumen de entrenamiento semanal del periodo.
@freezed
abstract class TrainingVolume with _$TrainingVolume {
  const factory TrainingVolume({
    required List<VolumePoint> points,
    required double averageMinutesPerWeek,
    required double averageCaloriesPerWeek,
    required double averageSessionsPerWeek,
  }) = _TrainingVolume;
}

/// Volumen de una semana.
@freezed
abstract class VolumePoint with _$VolumePoint {
  const factory VolumePoint({
    required DateTime weekStart,
    required int sessions,
    required int minutes,
    required int calories,
  }) = _VolumePoint;
}
