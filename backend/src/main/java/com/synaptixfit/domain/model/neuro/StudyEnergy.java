package com.synaptixfit.domain.model.neuro;

/**
 * Fórmula 1: gasto calórico de los bloques académicos.
 *
 * <p>RMR (Mifflin-St Jeor, 1990): {@code RMR = 10*peso + 6.25*altura - 5*edad + S}, con
 * S = +5 (hombre), -161 (mujer) o -78 (punto medio, cuando el sexo no es binario o no consta).
 * Gasto del bloque: {@code (RMR / 86400) * segundos * MET}, con MET cognitivo 1.8 para clase
 * y 1.3 para estudio, repaso y resto (Compendio de Actividades Físicas 2024).
 */
public final class StudyEnergy {

    public static final double MET_CLASS = 1.8;
    public static final double MET_STUDY = 1.3;
    private static final int SECONDS_PER_DAY = 86_400;

    private StudyEnergy() {
    }

    /** Tasa metabólica en reposo en kcal/día. */
    public static double restingMetabolicRate(double weightKg, double heightCm, int age, BiologicalSex sex) {
        double s = switch (sex) {
            case MALE -> 5.0;
            case FEMALE -> -161.0;
            case OTHER -> -78.0;
        };
        return 10.0 * weightKg + 6.25 * heightCm - 5.0 * age + s;
    }

    /** kcal de un bloque de {@code durationSeconds} con el MET indicado. */
    public static double blockCalories(double rmr, long durationSeconds, double met) {
        if (durationSeconds <= 0) {
            return 0;
        }
        return (rmr / SECONDS_PER_DAY) * durationSeconds * met;
    }

    /** MET cognitivo según el tipo de actividad del bloque ('clase' o cualquier otro). */
    public static double cognitiveMet(String activityType) {
        return activityType != null && activityType.strip().equalsIgnoreCase("clase") ? MET_CLASS : MET_STUDY;
    }
}
