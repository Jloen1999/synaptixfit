package com.synaptixfit.domain.model.admin;

import com.synaptixfit.domain.model.admin.AdminActivityAggregation.StudyInterval;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.StudyWeek;
import java.time.Instant;
import java.util.Collection;
import java.util.List;

/**
 * Estadísticas agregadas de un usuario.
 *
 * <p>{@code academicAdherencePercent} = horas reales / planificadas de las últimas
 * {@code adherenceWeeks} semanas registradas (máx. 4); nulo si no hay horas planificadas.
 */
public record AdminUserStats(long trainingSessions, long trainingMinutes, long caloriesBurned, Double averageRpe,
                             long routines, long activeRoutines, long challenges, long completedChallenges,
                             long badges, long subjects, long notes, long files, long completedStudyBlocks,
                             long studyMinutes, long focusSessions, long focusMinutes, long completedDeadlines,
                             long pendingDeadlines, long posts, long comments, long friends,
                             Integer academicAdherencePercent, int adherenceWeeks, Instant lastActivityAt) {

    /**
     * Combina los recuentos con las cifras que tienen regla: minutos de los bloques de estudio y
     * adherencia de las últimas semanas ({@link AdminActivityAggregation}).
     */
    public static AdminUserStats of(AdminUserCounts c, Collection<StudyInterval> studyBlocks,
                                    List<StudyWeek> recentWeeks) {
        return new AdminUserStats(c.trainingSessions(), c.trainingMinutes(), c.caloriesBurned(), c.averageRpe(),
                c.routines(), c.activeRoutines(), c.challenges(), c.completedChallenges(), c.badges(), c.subjects(),
                c.notes(), c.files(), c.completedStudyBlocks(), AdminActivityAggregation.studyMinutes(studyBlocks),
                c.focusSessions(), c.focusMinutes(), c.completedDeadlines(), c.pendingDeadlines(), c.posts(),
                c.comments(), c.friends(), AdminActivityAggregation.adherencePercent(recentWeeks), recentWeeks.size(),
                c.lastActivityAt());
    }
}
