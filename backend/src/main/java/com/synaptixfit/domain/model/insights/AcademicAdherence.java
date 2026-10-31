package com.synaptixfit.domain.model.insights;

/**
 * Adherencia académica semanal 0-100:
 * {@code 60 % cumplimiento de horas + 30 % entregas completadas + 10 % días con estudio}.
 * Sin horas planificadas o sin entregas en la semana, ese componente vale 0.5 (neutro). Solo cuenta
 * lo que ya tocaba: las horas planificadas se prorratean por los días transcurridos de la semana,
 * los días con estudio se comparan con esos días y las entregas son las que ya vencían (un lunes
 * por la mañana no es «baja adherencia»).
 *
 * @param studyDays días distintos de la semana con algún bloque de estudio completado (0-7)
 */
public record AcademicAdherence(double score, double hoursCompliance, double taskCompletion, int studyDays,
                                double studyDaysRatio) {

    public static AcademicAdherence compute(WeeklyAcademicLoad weekly, int deadlinesTotal, int deadlinesCompleted,
                                            int studyDays) {
        return compute(weekly, deadlinesTotal, deadlinesCompleted, studyDays, 7);
    }

    /** @param elapsedDays días de la semana transcurridos, hoy incluido (1-7) */
    public static AcademicAdherence compute(WeeklyAcademicLoad weekly, int deadlinesTotal, int deadlinesCompleted,
                                            int studyDays, int elapsedDays) {
        int elapsed = Math.max(1, Math.min(7, elapsedDays));
        double plannedSoFar = weekly.plannedStudyHours() * elapsed / 7.0;
        double hours = plannedSoFar > 0 ? clamp01(weekly.realStudyHours() / plannedSoFar) : 0.5;
        double tasks = deadlinesTotal > 0 ? clamp01((double) deadlinesCompleted / deadlinesTotal) : 0.5;
        int days = Math.max(0, Math.min(elapsed, studyDays));
        double daysRatio = days / (double) elapsed;
        double score = Math.max(0, Math.min(100, hours * 60 + tasks * 30 + daysRatio * 10));
        return new AcademicAdherence(score, hours, tasks, days, daysRatio);
    }

    private static double clamp01(double v) {
        return Math.max(0, Math.min(1, v));
    }
}
