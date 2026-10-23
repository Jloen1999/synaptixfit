package com.synaptixfit.domain.model.training.generation;

/** Contexto físico del usuario: tendencia de peso, racha y nivel. */
public record PhysiologicalContext(Double currentWeightKg, Double previousWeekWeightKg, int streak, int level) {

    public static final PhysiologicalContext NONE = new PhysiologicalContext(null, null, 1, 1);

    public Double weeklyWeightTrend() {
        if (currentWeightKg == null || previousWeekWeightKg == null) {
            return null;
        }
        return currentWeightKg - previousWeekWeightKg;
    }

    public boolean losingWeight() {
        Double t = weeklyWeightTrend();
        return t != null && t < -0.5;
    }

    public boolean gainingWeight() {
        Double t = weeklyWeightTrend();
        return t != null && t > 0.5;
    }
}
