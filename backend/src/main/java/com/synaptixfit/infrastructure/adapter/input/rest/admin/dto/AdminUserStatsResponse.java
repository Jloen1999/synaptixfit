package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import com.synaptixfit.domain.model.admin.AdminUserStats;
import java.time.Instant;

/** Estadísticas agregadas de un usuario. */
public record AdminUserStatsResponse(long trainingSessions, long trainingMinutes, long caloriesBurned,
                                     Double averageRpe, long routines, long activeRoutines, long challenges,
                                     long completedChallenges, long badges, long subjects, long notes, long files,
                                     long completedStudyBlocks, long studyMinutes, long focusSessions,
                                     long focusMinutes, long completedDeadlines, long pendingDeadlines, long posts,
                                     long comments, long friends, Integer academicAdherencePercent,
                                     int adherenceWeeks, Instant lastActivityAt) {

    public static AdminUserStatsResponse from(AdminUserStats s) {
        return new AdminUserStatsResponse(s.trainingSessions(), s.trainingMinutes(), s.caloriesBurned(),
                s.averageRpe(), s.routines(), s.activeRoutines(), s.challenges(), s.completedChallenges(), s.badges(),
                s.subjects(), s.notes(), s.files(), s.completedStudyBlocks(), s.studyMinutes(), s.focusSessions(),
                s.focusMinutes(), s.completedDeadlines(), s.pendingDeadlines(), s.posts(), s.comments(), s.friends(),
                s.academicAdherencePercent(), s.adherenceWeeks(), s.lastActivityAt());
    }
}
