package com.synaptixfit.domain.model.badge;

import java.time.LocalDate;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

/** Calcula el valor de cada criterio de insignia a partir de la actividad del usuario. */
public final class BadgeMetrics {

    private BadgeMetrics() {
    }

    /**
     * @param streakDays   racha diaria actual del usuario
     * @param badgesEarned insignias que ya tiene
     */
    public static Map<BadgeCriterion, Integer> compute(BadgeActivitySnapshot s, int streakDays, int badgesEarned,
                                                       LocalDate today) {
        Map<BadgeCriterion, Integer> m = new EnumMap<>(BadgeCriterion.class);
        m.put(BadgeCriterion.SESSIONS_COMPLETED, s.sessionsCompleted());
        m.put(BadgeCriterion.HIGH_RPE_SESSIONS, s.highRpeSessions());
        m.put(BadgeCriterion.CONSECUTIVE_CHECK_INS, ActivityDays.currentRun(s.checkInDays(), today));
        m.put(BadgeCriterion.STUDY_BLOCKS, s.studyBlocksCompleted());
        m.put(BadgeCriterion.STUDY_PLANS, s.studyPlans());
        m.put(BadgeCriterion.NOTES_CREATED, s.notesCreated());
        m.put(BadgeCriterion.FEED_POSTS, s.feedPosts());
        m.put(BadgeCriterion.LIKES_RECEIVED, s.likesReceived());
        m.put(BadgeCriterion.STREAK_DAYS, streakDays);
        m.put(BadgeCriterion.CHALLENGES_COMPLETED, s.challengesCompleted());
        m.put(BadgeCriterion.BADGES_EARNED, badgesEarned);
        m.put(BadgeCriterion.PLAN_ADHERENCE_WEEKS, adherentWeeks(s.weeklyStudyLoads(), today));
        return m;
    }

    /**
     * Semanas consecutivas (sin huecos) con al menos el 80 % de las horas planificadas, contando
     * hacia atrás desde la más reciente. La semana en curso no rompe la cuenta si aún no llega al 80 %.
     */
    public static int adherentWeeks(List<WeeklyStudyLoad> loads, LocalDate today) {
        List<WeeklyStudyLoad> sorted = loads.stream().filter(w -> w.plannedHours() > 0)
                .sorted(Comparator.comparing(WeeklyStudyLoad::weekStart).reversed()).toList();
        int count = 0;
        LocalDate expected = null;
        for (int i = 0; i < sorted.size(); i++) {
            WeeklyStudyLoad week = sorted.get(i);
            boolean inProgress = week.weekStart().isAfter(today.minusDays(7));
            if (i == 0 && inProgress && !week.adherent()) {
                expected = week.weekStart().minusWeeks(1);
                continue;
            }
            if (expected != null && !week.weekStart().equals(expected)) {
                break;
            }
            if (!week.adherent()) {
                break;
            }
            count++;
            expected = week.weekStart().minusWeeks(1);
        }
        return count;
    }
}
