import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/badge_category.dart';
import '../../enums/badge_criterion.dart';
import '../../enums/badge_rarity.dart';

part 'badge.freezed.dart';

/// Insignia del catálogo vista por el usuario, con su progreso hacia el criterio.
@freezed
abstract class Badge with _$Badge {
  const factory Badge({
    required String id,
    required String name,
    required String description,

    /// Emoji que representa la insignia.
    required String icon,
    required BadgeCategory category,
    required BadgeCriterion criterion,
    required int criterionValue,
    required BadgeRarity rarity,
    required int order,
    required bool earned,
    DateTime? earnedAt,

    /// Si una insignia obtenida se muestra en el perfil público.
    @Default(false) bool visible,
    required int currentValue,

    /// Progreso hacia el criterio entre 0 y 1.
    required double progress,
  }) = _Badge;
}
