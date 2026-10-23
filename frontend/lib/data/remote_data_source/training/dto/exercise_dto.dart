import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/training_enums.dart';
import '../../../../domain/models/training/exercise.dart';

part 'exercise_dto.freezed.dart';
part 'exercise_dto.g.dart';

@freezed
abstract class CatalogItemDto with _$CatalogItemDto {
  const factory CatalogItemDto({
    required int id,
    required String name,
    String? imageUrl,
  }) = _CatalogItemDto;

  const CatalogItemDto._();

  factory CatalogItemDto.fromJson(Map<String, dynamic> json) =>
      _$CatalogItemDtoFromJson(json);

  CatalogItem toDomain() => CatalogItem(id: id, name: name, imageUrl: imageUrl);
}

@freezed
abstract class ExerciseDto with _$ExerciseDto {
  const factory ExerciseDto({
    required String id,
    required String name,
    String? description,
    List<String>? instructions,
    String? difficulty,
    List<String>? purposes,
    String? modality,
    String? category,
    List<String>? measurementTypes,
    @Default(false) bool circuit,
    @Default(0) double met,
    String? gifUrl,
    String? previewUrl,
    List<CatalogItemDto>? bodyParts,
    List<CatalogItemDto>? targetMuscles,
    List<CatalogItemDto>? secondaryMuscles,
    List<CatalogItemDto>? equipment,
  }) = _ExerciseDto;

  const ExerciseDto._();

  factory ExerciseDto.fromJson(Map<String, dynamic> json) =>
      _$ExerciseDtoFromJson(json);

  Exercise toDomain() => Exercise(
    id: id,
    name: name,
    description: description,
    instructions: instructions ?? const [],
    difficulty: ExerciseDifficulty.fromApi(difficulty),
    purposes: purposes ?? const [],
    modality: Modality.fromApi(modality),
    category: ExerciseCategory.fromApi(category),
    measurementTypes: (measurementTypes ?? const [])
        .map(MeasurementType.fromApi)
        .toList(),
    circuit: circuit,
    met: met,
    gifUrl: _blankToNull(gifUrl),
    previewUrl: _blankToNull(previewUrl),
    bodyParts: _items(bodyParts),
    targetMuscles: _items(targetMuscles),
    secondaryMuscles: _items(secondaryMuscles),
    equipment: _items(equipment),
  );
}

@freezed
abstract class ExerciseFilterOptionsDto with _$ExerciseFilterOptionsDto {
  const factory ExerciseFilterOptionsDto({
    List<CatalogItemDto>? bodyParts,
    List<CatalogItemDto>? muscles,
    List<CatalogItemDto>? equipment,
  }) = _ExerciseFilterOptionsDto;

  const ExerciseFilterOptionsDto._();

  factory ExerciseFilterOptionsDto.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFilterOptionsDtoFromJson(json);

  ExerciseFilterOptions toDomain() => ExerciseFilterOptions(
    bodyParts: _items(bodyParts),
    muscles: _items(muscles),
    equipment: _items(equipment),
  );
}

List<CatalogItem> _items(List<CatalogItemDto>? items) =>
    (items ?? const []).map((i) => i.toDomain()).toList();

/// Las URLs vacías se tratan como ausentes.
String? _blankToNull(String? value) =>
    value == null || value.trim().isEmpty ? null : value;
