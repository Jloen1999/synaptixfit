package com.synaptixfit.domain.model.badge;

/**
 * Insignia del catálogo vista por un usuario.
 *
 * @param earned       la insignia obtenida o {@code null} si aún no la tiene
 * @param currentValue valor actual de la métrica (progreso hacia el criterio)
 */
public record BadgeView(Badge badge, UserBadge earned, int currentValue) {
}
