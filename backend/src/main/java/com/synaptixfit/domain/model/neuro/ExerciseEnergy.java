package com.synaptixfit.domain.model.neuro;

/**
 * Gasto calórico del ejercicio (Compendio de Actividades Físicas para Adultos 2024):
 * {@code kcal = MET * peso_kg * horas}. Sin peso válido se usan 70 kg.
 */
public final class ExerciseEnergy {

    public static final double DEFAULT_WEIGHT_KG = 70.0;
    public static final double REST_MET = 1.5;

    private ExerciseEnergy() {
    }

    public static double calories(double met, Double weightKg, long durationSeconds) {
        if (durationSeconds <= 0) {
            return 0;
        }
        double weight = weightKg == null || weightKg <= 0 ? DEFAULT_WEIGHT_KG : weightKg;
        return met * weight * (durationSeconds / 3600.0);
    }

    public static double restCalories(Double weightKg, long durationSeconds) {
        return calories(REST_MET, weightKg, durationSeconds);
    }

    /** MET del catálogo o, si falta, uno derivado de la modalidad. */
    public static double deriveMet(Double catalogMet, String modality, boolean circuit) {
        if (catalogMet != null && catalogMet > 0) {
            return catalogMet;
        }
        if (circuit) {
            return 8.0;
        }
        if (modality == null) {
            return 6.0;
        }
        return switch (modality) {
            case "movilidad" -> 2.3;
            case "metabolica" -> 8.0;
            case "aerobica" -> 8.3;
            default -> 6.0;
        };
    }
}
