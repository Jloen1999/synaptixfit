package com.synaptixfit.domain.model.training.generation;

/**
 * Situación académica de la semana (datos del planificador y de los indicadores, solo lectura).
 *
 * @param plannedStudyHours  horas de estudio planeadas en la semana
 * @param realStudyHours     horas de estudio realizadas (bloques completados)
 * @param stressLevel        estrés académico 1-10
 * @param evaluationsThisWeek entregas y exámenes con fecha en la semana
 * @param evaluationsCompleted de ellas, cuántas están completadas
 * @param studyDaysThisWeek  días distintos con algún bloque de estudio completado
 * @param averageSleepHours  horas de sueño medias
 * @param daysToNextExam     días hasta el próximo examen o entrega pendiente (null si no hay)
 * @param cognitiveLoad      carga cognitiva acumulada 0-1 (null si no hay estado)
 * @param acwr               ratio de carga aguda/crónica (null sin historial)
 */
public record AcademicContext(double plannedStudyHours, double realStudyHours, double stressLevel,
                              int evaluationsThisWeek, int evaluationsCompleted, int studyDaysThisWeek,
                              double averageSleepHours, Integer daysToNextExam, Double cognitiveLoad, Double acwr) {

    public static final AcademicContext NONE = new AcademicContext(0, 0, 5, 0, 0, 0, 7, null, null, null);

    /** Copia con la carga cognitiva y el ACWR recalculados por los indicadores. */
    public AcademicContext withInsights(Double freshCognitiveLoad, Double freshAcwr) {
        return new AcademicContext(plannedStudyHours, realStudyHours, stressLevel, evaluationsThisWeek,
                evaluationsCompleted, studyDaysThisWeek, averageSleepHours, daysToNextExam, freshCognitiveLoad,
                freshAcwr);
    }

    public boolean examWithinSevenDays() {
        return daysToNextExam != null && daysToNextExam <= 7;
    }

    /**
     * Adherencia académica 0-100 (fórmula heredada): 60 % cumplimiento de horas + 30 % tareas
     * completadas + 10 % días con estudio. Sin datos, cada componente vale 0,5.
     */
    public double adherence() {
        double hours = plannedStudyHours > 0 ? clamp01(realStudyHours / plannedStudyHours) : 0.5;
        double tasks = evaluationsThisWeek > 0 ? clamp01((double) evaluationsCompleted / evaluationsThisWeek) : 0.5;
        double days = clamp01(studyDaysThisWeek / 7.0);
        return Math.max(0, Math.min(100, hours * 60 + tasks * 30 + days * 10));
    }

    static double clamp01(double v) {
        return Math.max(0, Math.min(1, v));
    }
}
