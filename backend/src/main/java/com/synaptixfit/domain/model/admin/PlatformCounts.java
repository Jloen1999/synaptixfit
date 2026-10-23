package com.synaptixfit.domain.model.admin;

/**
 * Recuentos simples de la plataforma en un instante (sin reglas de actividad diaria: esas las calcula
 * {@link AdminActivityAggregation}). Se combinan en {@link PlatformMetrics#of}.
 */
public record PlatformCounts(long totalUsers, long activeRoutines, long activeChallenges, long reportedPosts,
                             long reportedComments, long shadowbannedUsers) {
}
