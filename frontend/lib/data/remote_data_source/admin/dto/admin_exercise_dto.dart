import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/admin/admin_exercise_difficulty.dart';
import '../../../../domain/enums/admin/admin_exercise_modality.dart';
import '../../../../domain/enums/admin/admin_exercise_purpose.dart';
import '../../../../domain/enums/admin/admin_measurement_type.dart';
import '../../../../domain/models/admin/admin_exercise.dart';
import 'admin_json.dart';

part 'admin_exercise_dto.freezed.dart';
part 'admin_exercise_dto.g.dart';

@freezed
abstract class AdminCatalogItemDto with _$AdminCatalogItemDto {
  const factory AdminCatalogItemDto({
    required int id,
    @Default('') String name,
    String? imageUrl,
  }) = _AdminCatalogItemDto;

  const AdminCatalogItemDto._();

  factory AdminCatalogItemDto.fromJson(Map<String, dynamic> json) =>
      _$AdminCatalogItemDtoFromJson(json);

  AdminCatalogItem toDomain() =>
      AdminCatalogItem(id: id, name: name, imageUrl: imageUrl);
}

@freezed
abstract class AdminExerciseOptionsDto with _$AdminExerciseOptionsDto {
  const factory AdminExerciseOptionsDto({
    @Default(<AdminCatalogItemDto>[]) List<AdminCatalogItemDto> bodyParts,
    @Default(<AdminCatalogItemDto>[]) List<AdminCatalogItemDto> muscles,
    @Default(<AdminCatalogItemDto>[]) List<AdminCatalogItemDto> equipment,
  }) = _AdminExerciseOptionsDto;

  const AdminExerciseOptionsDto._();

  factory AdminExerciseOptionsDto.fromJson(Map<String, dynamic> json) =>
      _$AdminExerciseOptionsDtoFromJson(json);

  AdminExerciseOptions toDomain() => AdminExerciseOptions(
    bodyParts: [for (final i in bodyParts) i.toDomain()],
    muscles: [for (final i in muscles) i.toDomain()],
    equipment: [for (final i in equipment) i.toDomain()],
  );
}

@freezed
abstract class AdminExerciseDto with _$AdminExerciseDto {
  const factory AdminExerciseDto({
    required String id,
    @Default('') String name,
    String? description,
    @Default(<String>[]) List<String> instructions,
    String? difficulty,
    @Default(<String>[]) List<String> purposes,
    String? modality,
    @Default(<String>[]) List<String> measurementTypes,
    @Default(false) bool circuit,
    @Default(true) bool active,
    @Default(6.0) double met,
    String? gifUrl,
    String? previewUrl,
    @Default(<AdminCatalogItemDto>[]) List<AdminCatalogItemDto> bodyParts,
    @Default(<AdminCatalogItemDto>[]) List<AdminCatalogItemDto> targetMuscles,
    @Default(<AdminCatalogItemDto>[])
    List<AdminCatalogItemDto> secondaryMuscles,
    @Default(<AdminCatalogItemDto>[]) List<AdminCatalogItemDto> equipment,
    String? createdAt,
    String? updatedAt,
  }) = _AdminExerciseDto;

  const AdminExerciseDto._();

  factory AdminExerciseDto.fromJson(Map<String, dynamic> json) =>
      _$AdminExerciseDtoFromJson(json);

  AdminExercise toDomain() => AdminExercise(
    id: id,
    name: name,
    description: description,
    instructions: instructions,
    difficulty: AdminExerciseDifficulty.fromApi(difficulty),
    purposes: AdminExercisePurpose.listFromApi(purposes),
    modality: AdminExerciseModality.fromApi(modality),
    measurementTypes: AdminMeasurementType.listFromApi(measurementTypes),
    circuit: circuit,
    active: active,
    met: met,
    gifUrl: gifUrl,
    previewUrl: previewUrl,
    bodyParts: [for (final i in bodyParts) i.toDomain()],
    targetMuscles: [for (final i in targetMuscles) i.toDomain()],
    secondaryMuscles: [for (final i in secondaryMuscles) i.toDomain()],
    equipment: [for (final i in equipment) i.toDomain()],
    createdAt: AdminJson.instant(createdAt),
    updatedAt: AdminJson.instant(updatedAt),
  );
}

@freezed
abstract class AdminExerciseDeletionDto with _$AdminExerciseDeletionDto {
  const factory AdminExerciseDeletionDto({
    @Default(false) bool deleted,
    @Default(false) bool deactivated,
  }) = _AdminExerciseDeletionDto;

  const AdminExerciseDeletionDto._();

  factory AdminExerciseDeletionDto.fromJson(Map<String, dynamic> json) =>
      _$AdminExerciseDeletionDtoFromJson(json);

  AdminExerciseDeletion toDomain() =>
      AdminExerciseDeletion(deleted: deleted, deactivated: deactivated);
}

/// Nombre en otros idiomas (`ExerciseNamesDto`); los vacíos llegan nulos.
@freezed
abstract class AdminExerciseNamesDto with _$AdminExerciseNamesDto {
  const factory AdminExerciseNamesDto({String? en, String? fr, String? pt}) =
      _AdminExerciseNamesDto;

  const AdminExerciseNamesDto._();

  factory AdminExerciseNamesDto.fromJson(Map<String, dynamic> json) =>
      _$AdminExerciseNamesDtoFromJson(json);

  AdminExerciseNames toDomain() =>
      AdminExerciseNames(en: en ?? '', fr: fr ?? '', pt: pt ?? '');
}

/// Cuerpo de `POST/PUT /api/v1/admin/exercises` (`ExerciseRequest`).
abstract final class AdminExerciseRequest {
  static Map<String, dynamic> fromDraft(AdminExerciseDraft draft) {
    String? optional(String value) =>
        value.trim().isEmpty ? null : value.trim();
    return {
      'name': draft.name.trim(),
      'description': optional(draft.description),
      'instructions': [
        for (final step in draft.instructions)
          if (step.trim().isNotEmpty) step.trim(),
      ],
      'difficulty': draft.difficulty.apiValue,
      'purposes': [for (final p in draft.purposes) p.apiValue],
      'modality': draft.modality.apiValue,
      'measurementTypes': [for (final m in draft.measurementTypes) m.apiValue],
      'circuit': draft.circuit,
      'met': draft.met,
      'gifUrl': optional(draft.gifUrl),
      'previewUrl': optional(draft.previewUrl),
      'bodyPartIds': draft.bodyPartIds.toList(),
      'targetMuscleIds': draft.targetMuscleIds.toList(),
      'secondaryMuscleIds': draft.secondaryMuscleIds.toList(),
      'equipmentIds': draft.equipmentIds.toList(),
      // Sin nombres cargados no se envían: el servidor deja los que tenga.
      if (draft.translations case final names?)
        'translations': {
          'en': optional(names.en),
          'fr': optional(names.fr),
          'pt': optional(names.pt),
        },
    };
  }
}
