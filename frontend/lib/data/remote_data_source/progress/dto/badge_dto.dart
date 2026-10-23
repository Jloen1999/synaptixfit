import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/badge_category.dart';
import '../../../../domain/enums/badge_criterion.dart';
import '../../../../domain/enums/badge_rarity.dart';
import '../../../../domain/models/progress/badge.dart';

part 'badge_dto.freezed.dart';
part 'badge_dto.g.dart';

/// `BadgeResponse` de la API.
@freezed
abstract class BadgeDto with _$BadgeDto {
  const factory BadgeDto({
    required String id,
    required String name,
    @Default('') String description,
    @Default('') String icon,
    String? category,
    String? criterionType,
    @Default(0) int criterionValue,
    String? rarity,
    @Default(0) int order,
    @Default(false) bool earned,
    DateTime? earnedAt,
    @Default(false) bool visible,
    @Default(0) int currentValue,
    @Default(0) double progress,
  }) = _BadgeDto;

  const BadgeDto._();

  factory BadgeDto.fromJson(Map<String, dynamic> json) =>
      _$BadgeDtoFromJson(json);

  Badge toDomain() => Badge(
    id: id,
    name: name,
    description: description,
    icon: icon,
    category: BadgeCategory.fromApi(category),
    criterion: BadgeCriterion.fromApi(criterionType),
    criterionValue: criterionValue,
    rarity: BadgeRarity.fromApi(rarity),
    order: order,
    earned: earned,
    earnedAt: earnedAt?.toLocal(),
    visible: earned && visible,
    currentValue: currentValue,
    progress: progress.clamp(0, 1).toDouble(),
  );
}
