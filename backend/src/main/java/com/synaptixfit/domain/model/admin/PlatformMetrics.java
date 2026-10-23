package com.synaptixfit.domain.model.admin;

/** Indicadores globales de la plataforma (el «hoy» se calcula en UTC). */
public record PlatformMetrics(long totalUsers, long activeUsersToday, long trainingSessionsToday,
                              long activeRoutines, long activeChallenges, long pendingReportedContent,
                              long newUsersToday, long shadowbannedUsers) {

    /** Recuentos de la plataforma más la actividad de hoy ({@link AdminActivityAggregation#daily}). */
    public static PlatformMetrics of(PlatformCounts counts, DailyActivityPoint today) {
        return new PlatformMetrics(counts.totalUsers(), today.activeUsers(), today.trainingSessions(),
                counts.activeRoutines(), counts.activeChallenges(), counts.reportedPosts() + counts.reportedComments(),
                today.signups(), counts.shadowbannedUsers());
    }
}
