package com.synaptixfit.domain.model.insights;

/**
 * Adherencia académica semanal 0-100:
 * {@code 60 % cumplimiento de horas + 30 % entregas completadas + 10 % días con estudio}.
 * Sin horas planificadas o sin entregas en la semana, ese componente vale 0.5 (neutro).
 *
 * @param studyDays días distintos de la semana con algún bloque de estudio completado (0-7)
 */
public record AcademicAdherence(double score, double hoursCompliance, double taskCompletion, int studyDays,
                                double studyDaysRatio) {

    public static AcademicAdherence compute(WeeklyAcademicLoad weekly, int deadlinesTotal, int deadlinesCompleted,
                                            int studyDays) {
        double hours = weekly.plannedStudyHours() > 0
                ? clamp01((double) weekly.realStudyHours() / weekly.plannedStudyHours()) : 0.5;
        double tasks = deadlinesTotal > 0 ? clamp01((double) deadlinesCompleted / deadlinesTotal) : 0.5;
        int days = Math.max(0, Math.min(7, studyDays));
        double daysRatio = days / 7.0;
        double score = Math.max(0, Math.min(100, hours * 60 + tasks * 30 + daysRatio * 10));
        return new AcademicAdherence(score, hours, tasks, days, daysRatio);
    }

    private static double clamp01(double v) {
        return Math.max(0, Math.min(1, v));
    }
}
