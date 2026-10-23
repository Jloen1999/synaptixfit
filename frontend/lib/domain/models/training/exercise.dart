import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/training_enums.dart';
import 'routine.dart';

part 'exercise.freezed.dart';

/// Músculo, parte del cuerpo o equipamiento del catálogo.
@freezed
abstract class CatalogItem with _$CatalogItem {
  const factory CatalogItem({
    required int id,
    required String name,
    String? imageUrl,
  }) = _CatalogItem;
}

/// Ejercicio del catálogo.
@freezed
abstract class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String name,
    String? description,
    @Default(<String>[]) List<String> instructions,
    required ExerciseDifficulty difficulty,

    /// Etiquetas de finalidad tal como las da la API («Hipertrofia Muscular»…).
    @Default(<String>[]) List<String> purposes,
    required Modality modality,
    @Default(ExerciseCategory.strength) ExerciseCategory category,
    @Default(<MeasurementType>[]) List<MeasurementType> measurementTypes,
    @Default(false) bool circuit,
    required double met,
    String? gifUrl,
    String? previewUrl,
    @Default(<CatalogItem>[]) List<CatalogItem> bodyParts,
    @Default(<CatalogItem>[]) List<CatalogItem> targetMuscles,
    @Default(<CatalogItem>[]) List<CatalogItem> secondaryMuscles,
    @Default(<CatalogItem>[]) List<CatalogItem> equipment,
  }) = _Exercise;

  const Exercise._();

  /// Imagen fija para miniaturas (o el GIF si no hay vista previa).
  String? get thumbnailUrl => previewUrl ?? gifUrl;

  /// Parámetros iniciales razonables al añadirlo a una rutina, según cómo se mide.
  ExerciseParameters get defaultParameters {
    final timed =
        measurementTypes.contains(MeasurementType.time) &&
        !measurementTypes.contains(MeasurementType.repetitions);
    if (modality == Modality.aerobic || timed) {
      return const ExerciseParameters(
        sets: 1,
        reps: 1,
        restSeconds: 60,
        targetDurationSeconds: 600,
      );
    }
    if (modality == Modality.mobility) {
      return const ExerciseParameters(sets: 2, reps: 10, restSeconds: 30);
    }
    return const ExerciseParameters();
  }
}

/// Valores disponibles para filtrar el catálogo.
@freezed
abstract class ExerciseFilterOptions with _$ExerciseFilterOptions {
  const factory ExerciseFilterOptions({
    @Default(<CatalogItem>[]) List<CatalogItem> bodyParts,
    @Default(<CatalogItem>[]) List<CatalogItem> muscles,
    @Default(<CatalogItem>[]) List<CatalogItem> equipment,
  }) = _ExerciseFilterOptions;
}

/// Criterios de búsqueda del catálogo. Los nulos no filtran.
@freezed
abstract class ExerciseSearchCriteria with _$ExerciseSearchCriteria {
  const factory ExerciseSearchCriteria({
    String? query,
    int? bodyPartId,
    int? muscleId,
    int? equipmentId,
    ExerciseDifficulty? difficulty,
    Modality? modality,
    TrainingGoal? purpose,
    ExerciseCategory? category,
  }) = _ExerciseSearchCriteria;

  const ExerciseSearchCriteria._();

  /// Número de filtros activos (sin contar el texto).
  int get activeFilters => [
    bodyPartId,
    muscleId,
    equipmentId,
    difficulty,
    modality,
    purpose,
  ].where((f) => f != null).length;
}

/// Calentamiento (movilidad) y vuelta a la calma (estiramientos) para los
/// músculos de una sesión. Lo decide el servidor.
@freezed
abstract class SessionBookends with _$SessionBookends {
  const factory SessionBookends({
    @Default(<Exercise>[]) List<Exercise> warmUp,
    @Default(<Exercise>[]) List<Exercise> coolDown,
  }) = _SessionBookends;
}
