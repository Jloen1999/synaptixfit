package com.synaptixfit.domain.model.admin;

import java.time.Instant;

/**
 * Recuentos y sumas simples de la actividad de un usuario tal como los devuelve la base de datos.
 * Las cifras con regla (minutos de estudio y adherencia) se añaden en {@link AdminUserStats#of}.
 */
public record AdminUserCounts(long trainingSessions, long trainingMinutes, long caloriesBurned, Double averageRpe,
                              long routines, long activeRoutines, long challenges, long completedChallenges,
                              long badges, long subjects, long notes, long files, long completedStudyBlocks,
                              long focusSessions, long focusMinutes, long completedDeadlines, long pendingDeadlines,
                              long posts, long comments, long friends, Instant lastActivityAt) {
}
