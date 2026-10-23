package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.badge;

import com.synaptixfit.domain.model.badge.Badge;
import com.synaptixfit.domain.model.badge.BadgeCategory;
import com.synaptixfit.domain.model.badge.BadgeCriterion;
import com.synaptixfit.domain.model.badge.BadgeRarity;
import com.synaptixfit.domain.model.badge.UserBadge;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.badge.BadgeEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.badge.UserBadgeEntity;

/** Insignias de dominio ↔ entidades; traduce categoría y rareza del vocabulario en español. */
public final class BadgePersistenceMapper {

    private BadgePersistenceMapper() {
    }

    public static Badge toDomain(BadgeEntity e) {
        return new Badge(e.getId(), e.getNombre(), e.getDescripcion(), e.getIcono(), category(e.getCategoria()),
                BadgeCriterion.fromCode(e.getCriterioTipo()), e.getCriterioValor(), rarity(e.getRareza()), e.getOrden());
    }

    public static UserBadge toDomain(UserBadgeEntity e) {
        return new UserBadge(e.getId(), e.getUsuarioId(), e.getInsigniaId(), e.getObtenidaEn(), e.isNotificada(),
                e.isVisible());
    }

    public static void copyToEntity(UserBadge b, UserBadgeEntity e) {
        e.setId(b.id());
        e.setUsuarioId(b.userId());
        e.setInsigniaId(b.badgeId());
        e.setObtenidaEn(b.earnedAt());
        e.setNotificada(b.notified());
        e.setVisible(b.visible());
    }

    private static BadgeCategory category(String value) {
        return switch (value) {
            case "entrenamiento" -> BadgeCategory.TRAINING;
            case "estudio" -> BadgeCategory.STUDY;
            case "social" -> BadgeCategory.SOCIAL;
            case "racha" -> BadgeCategory.STREAK;
            default -> BadgeCategory.SPECIAL;
        };
    }

    private static BadgeRarity rarity(String value) {
        return switch (value) {
            case "rara" -> BadgeRarity.RARE;
            case "epica" -> BadgeRarity.EPIC;
            case "legendaria" -> BadgeRarity.LEGENDARY;
            default -> BadgeRarity.COMMON;
        };
    }
}
