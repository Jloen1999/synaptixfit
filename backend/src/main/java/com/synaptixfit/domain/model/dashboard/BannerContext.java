package com.synaptixfit.domain.model.dashboard;

import com.synaptixfit.domain.model.insights.AcwrZone;
import com.synaptixfit.domain.model.user.UsageFocus;

/**
 * Señales del día que alimentan las reglas del banner. Los valores desconocidos son null (no se
 * interpretan como bajos).
 *
 * @param daysUntilNextDeadline días hasta la entrega/examen pendiente más próximo de los próximos 7 días
 * @param recentFatigueScore    fatiga media (0-100) de los check-ins de los últimos 3 días
 * @param weeklyStress          estrés de la carga académica semanal (1-10)
 * @param daysSinceLastSession  días desde la última sesión de entrenamiento (null si nunca entrenó)
 * @param focus                 enfoque de uso: solo se proponen avisos de los ámbitos que usa
 */
public record BannerContext(AcwrZone zone, Double acwr, int maxStudyMinutes, int upcomingDeadlines,
                            Integer daysUntilNextDeadline, Integer recentFatigueScore, Double adherence,
                            Double energy, boolean checkInDone, Integer weeklyStress, double attentionCapacity,
                            double cognitiveLoad, int trainingStreak, int studyStreakDays,
                            Integer daysSinceLastSession, UsageFocus focus) {

    /** Contexto de alguien que usa la app completa (estudios y deporte). */
    public BannerContext(AcwrZone zone, Double acwr, int maxStudyMinutes, int upcomingDeadlines,
                         Integer daysUntilNextDeadline, Integer recentFatigueScore, Double adherence,
                         Double energy, boolean checkInDone, Integer weeklyStress, double attentionCapacity,
                         double cognitiveLoad, int trainingStreak, int studyStreakDays,
                         Integer daysSinceLastSession) {
        this(zone, acwr, maxStudyMinutes, upcomingDeadlines, daysUntilNextDeadline, recentFatigueScore, adherence,
                energy, checkInDone, weeklyStress, attentionCapacity, cognitiveLoad, trainingStreak, studyStreakDays,
                daysSinceLastSession, UsageFocus.BOTH);
    }

    public BannerContext {
        focus = focus == null ? UsageFocus.BOTH : focus;
    }
}
