package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import com.synaptixfit.domain.model.admin.PlatformMetrics;

/** Indicadores globales del panel («hoy» en UTC). */
public record PlatformMetricsResponse(long totalUsers, long activeUsersToday, long trainingSessionsToday,
                                      long activeRoutines, long activeChallenges, long pendingReportedContent,
                                      long newUsersToday, long shadowbannedUsers) {

    public static PlatformMetricsResponse from(PlatformMetrics m) {
        return new PlatformMetricsResponse(m.totalUsers(), m.activeUsersToday(), m.trainingSessionsToday(),
                m.activeRoutines(), m.activeChallenges(), m.pendingReportedContent(), m.newUsersToday(),
                m.shadowbannedUsers());
    }
}
