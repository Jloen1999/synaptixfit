package com.synaptixfit.domain.model.badge;

import java.util.Map;
import java.util.UUID;

/** Insignia del catálogo. */
public record Badge(UUID id, String name, String description, String icon, BadgeCategory category,
                    BadgeCriterion criterion, int criterionValue, BadgeRarity rarity, int order) {

    /** Valor actual de la métrica de esta insignia. */
    public int currentValue(Map<BadgeCriterion, Integer> metrics) {
        return metrics.getOrDefault(criterion, 0);
    }

    /** La insignia se obtiene si la métrica alcanza el valor del criterio. */
    public boolean isMetBy(Map<BadgeCriterion, Integer> metrics) {
        return criterion != BadgeCriterion.UNKNOWN && currentValue(metrics) >= criterionValue;
    }
}
