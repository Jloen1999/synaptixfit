package com.synaptixfit.domain.model.insights;

/**
 * Factor de Carga Total (FCT) 0-1: combina la carga académica de la semana y el check-in de hoy.
 *
 * <pre>
 * 0.25·min(1, horasEstudio/30) + 0.25·estrés/10 + 0.15·min(1, evaluaciones/5)
 * + 0.15·max(0, (8 - horasSueño)/8) + [check-in] 0.10·(dolor-1)/4 + 0.10·(6-energía)/5
 * </pre>
 */
public record TotalLoadFactor(double value, LoadLevel level) {

    static final double STUDY_HOURS_THRESHOLD = 30.0;
    static final double SLEEP_HOURS_THRESHOLD = 8.0;

    /** Nivel cualitativo sobre el valor en porcentaje: &lt;30 bajo, &lt;60 moderado, &lt;80 alto, resto crítico. */
    public enum LoadLevel {
        LOW, MODERATE, HIGH, CRITICAL;

        static LoadLevel of(double percent) {
            if (percent < 30) {
                return LOW;
            }
            if (percent < 60) {
                return MODERATE;
            }
            return percent < 80 ? HIGH : CRITICAL;
        }
    }

    /** @param checkIn check-in de hoy (puede ser null) */
    public static TotalLoadFactor compute(WeeklyAcademicLoad weekly, DailyCheckIn checkIn) {
        double fct = clamp01(weekly.realStudyHours() / STUDY_HOURS_THRESHOLD) * 0.25
                + clamp01(weekly.stressLevel() / 10.0) * 0.25
                + clamp01(weekly.evaluations() / 5.0) * 0.15
                + clamp01((SLEEP_HOURS_THRESHOLD - weekly.avgSleepHours()) / SLEEP_HOURS_THRESHOLD) * 0.15;
        if (checkIn != null) {
            fct += clamp01((checkIn.soreness() - 1) / 4.0) * 0.10;
            fct += clamp01((6 - checkIn.energy()) / 5.0) * 0.10;
        }
        double value = clamp01(fct);
        return new TotalLoadFactor(value, LoadLevel.of(value * 100));
    }

    public double percent() {
        return value * 100;
    }

    private static double clamp01(double v) {
        return Math.max(0, Math.min(1, v));
    }
}
