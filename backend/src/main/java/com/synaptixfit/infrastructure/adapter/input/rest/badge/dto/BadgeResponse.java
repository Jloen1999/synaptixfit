package com.synaptixfit.infrastructure.adapter.input.rest.badge.dto;

import com.synaptixfit.domain.model.badge.Badge;
import com.synaptixfit.domain.model.badge.BadgeCategory;
import com.synaptixfit.domain.model.badge.BadgeCriterion;
import com.synaptixfit.domain.model.badge.BadgeRarity;
import com.synaptixfit.domain.model.badge.BadgeView;
import java.time.Instant;
import java.util.UUID;

/**
 * Insignia vista por el usuario. {@code currentValue} es el valor actual de la métrica y
 * {@code progress} (0-1) cuánto falta para {@code criterionValue}. {@code earnedAt},
 * {@code notified} y {@code visible} solo tienen sentido si {@code earned}.
 */
public record BadgeResponse(UUID id, String name, String description, String icon, BadgeCategory category,
                            BadgeCriterion criterionType, int criterionValue, BadgeRarity rarity, int order,
                            boolean earned, Instant earnedAt, boolean notified, boolean visible, int currentValue,
                            double progress) {

    public static BadgeResponse from(BadgeView v) {
        Badge b = v.badge();
        boolean earned = v.earned() != null;
        int current = earned ? Math.max(v.currentValue(), b.criterionValue()) : v.currentValue();
        double progress = earned || b.criterionValue() <= 0 ? 1.0
                : Math.min(1.0, (double) current / b.criterionValue());
        return new BadgeResponse(b.id(), b.name(), b.description(), b.icon(), b.category(), b.criterion(),
                b.criterionValue(), b.rarity(), b.order(), earned, earned ? v.earned().earnedAt() : null,
                earned && v.earned().notified(), earned && v.earned().visible(), current, progress);
    }
}
