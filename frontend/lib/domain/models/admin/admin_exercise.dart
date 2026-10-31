import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/admin/admin_exercise_difficulty.dart';
import '../../enums/admin/admin_exercise_modality.dart';
import '../../enums/admin/admin_exercise_purpose.dart';
import '../../enums/admin/admin_measurement_type.dart';

part 'admin_exercise.freezed.dart';

/// Elemento de un catálogo auxiliar (músculo, parte del cuerpo, equipamiento).
@freezed
abstract class AdminCatalogItem with _$AdminCatalogItem {
  const factory AdminCatalogItem({
    required int id,
    required String name,
    String? imageUrl,
  }) = _AdminCatalogItem;
}

/// Opciones para los selectores del formulario de ejercicios.
@freezed
abstract class AdminExerciseOptions with _$AdminExerciseOptions {
  const factory AdminExerciseOptions({
    @Default(<AdminCatalogItem>[]) List<AdminCatalogItem> bodyParts,
    @Default(<AdminCatalogItem>[]) List<AdminCatalogItem> muscles,
    @Default(<AdminCatalogItem>[]) List<AdminCatalogItem> equipment,
  }) = _AdminExerciseOptions;
}

/// Ejercicio del catálogo tal como lo ve el administrador (incluye inactivos).
@freezed
abstract class AdminExercise with _$AdminExercise {
  const factory AdminExercise({
    required String id,
    required String name,
    String? description,
    @Default(<String>[]) List<String> instructions,
    required AdminExerciseDifficulty difficulty,
    @Default(<AdminExercisePurpose>[]) List<AdminExercisePurpose> purposes,
    required AdminExerciseModality modality,
    @Default(<AdminMeasurementType>[])
    List<AdminMeasurementType> measurementTypes,
    required bool circuit,
    required bool active,
    required double met,
    String? gifUrl,
    String? previewUrl,
    @Default(<AdminCatalogItem>[]) List<AdminCatalogItem> bodyParts,
    @Default(<AdminCatalogItem>[]) List<AdminCatalogItem> targetMuscles,
    @Default(<AdminCatalogItem>[]) List<AdminCatalogItem> secondaryMuscles,
    @Default(<AdminCatalogItem>[]) List<AdminCatalogItem> equipment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AdminExercise;
}

/// Nombre de un ejercicio en los demás idiomas de la app. El español es el
/// canónico (lo usan las reglas de rutinas); un idioma vacío se ve en español.
@freezed
abstract class AdminExerciseNames with _$AdminExerciseNames {
  const factory AdminExerciseNames({
    @Default('') String en,
    @Default('') String fr,
    @Default('') String pt,
  }) = _AdminExerciseNames;

  const AdminExerciseNames._();

  bool get isEmpty =>
      en.trim().isEmpty && fr.trim().isEmpty && pt.trim().isEmpty;

  bool get isValid =>
      en.length <= AdminExerciseDraft.nameMax &&
      fr.length <= AdminExerciseDraft.nameMax &&
      pt.length <= AdminExerciseDraft.nameMax;
}

/// Datos editables de un ejercicio (alta y edición).
@freezed
abstract class AdminExerciseDraft with _$AdminExerciseDraft {
  const factory AdminExerciseDraft({
    @Default('') String name,
    @Default('') String description,
    @Default(<String>[]) List<String> instructions,
    @Default(AdminExerciseDifficulty.beginner)
    AdminExerciseDifficulty difficulty,
    @Default(<AdminExercisePurpose>{}) Set<AdminExercisePurpose> purposes,
    @Default(AdminExerciseModality.strength) AdminExerciseModality modality,
    @Default(<AdminMeasurementType>{})
    Set<AdminMeasurementType> measurementTypes,
    @Default(false) bool circuit,
    @Default(6.0) double met,
    @Default('') String gifUrl,
    @Default('') String previewUrl,
    @Default(<int>{}) Set<int> bodyPartIds,
    @Default(<int>{}) Set<int> targetMuscleIds,
    @Default(<int>{}) Set<int> secondaryMuscleIds,
    @Default(<int>{}) Set<int> equipmentIds,

    /// Nulo si no se pudieron cargar: al guardar no se tocan.
    @Default(AdminExerciseNames()) AdminExerciseNames? translations,
  }) = _AdminExerciseDraft;

  const AdminExerciseDraft._();

  /// Borrador inicial a partir de un ejercicio existente.
  factory AdminExerciseDraft.fromExercise(AdminExercise e) =>
      AdminExerciseDraft(
        name: e.name,
        description: e.description ?? '',
        instructions: e.instructions,
        difficulty: e.difficulty,
        purposes: e.purposes.toSet(),
        modality: e.modality,
        measurementTypes: e.measurementTypes.toSet(),
        circuit: e.circuit,
        met: e.met,
        gifUrl: e.gifUrl ?? '',
        previewUrl: e.previewUrl ?? '',
        bodyPartIds: {for (final i in e.bodyParts) i.id},
        targetMuscleIds: {for (final i in e.targetMuscles) i.id},
        secondaryMuscleIds: {for (final i in e.secondaryMuscles) i.id},
        equipmentIds: {for (final i in e.equipment) i.id},
      );

  /// Límites que acepta la API (`ExerciseRequest`).
  static const nameMin = 2;
  static const nameMax = 200;
  static const descriptionMax = 4000;
  static const instructionMax = 1000;
  static const instructionsMax = 30;
  static const metMin = 1.0;
  static const metMax = 25.0;
  static const urlMax = 2048;

  bool get isNameValid {
    final length = name.trim().length;
    return length >= nameMin && length <= nameMax;
  }

  bool get isMetValid => met >= metMin && met <= metMax;

  bool get areInstructionsValid =>
      instructions.length <= instructionsMax &&
      instructions.every((i) => i.length <= instructionMax);

  bool get isValid =>
      isNameValid &&
      isMetValid &&
      areInstructionsValid &&
      description.length <= descriptionMax &&
      gifUrl.length <= urlMax &&
      previewUrl.length <= urlMax &&
      (translations?.isValid ?? true);
}

/// Resultado de borrar un ejercicio: si está en uso se desactiva en su lugar.
@freezed
abstract class AdminExerciseDeletion with _$AdminExerciseDeletion {
  const factory AdminExerciseDeletion({
    required bool deleted,
    required bool deactivated,
  }) = _AdminExerciseDeletion;
}
