package com.synaptixfit.domain.model.insights;

/**
 * Estado energético 0-100 a partir del check-in y de la carga académica de la semana, con
 * "compuertas" (gates) que lo hunden cuando un factor es crítico.
 *
 * <pre>
 * base = 0.30·energía + 0.25·sueño + 0.20·recuperación + 0.15·cognitivo + 0.10·estrés   (cada uno 0-100)
 * valor = base · gateSueño · gateDolor · gateEnergía
 * </pre>
 * Corrección respecto a la app antigua: la recuperación era {@code (5 - dolor) / 5} (máximo 80 %
 * con dolor 1); ahora es {@code (5 - dolor) / 4}, que va de 0 a 100 %.
 */
public record EnergyScore(double score, double base, double dailyEnergy, double sleep, double recovery,
                          double cognitive, double stress, double sleepGate, double sorenessGate,
                          double energyGate) {

    static final double STUDY_HOURS_SATURATION = 40.0;

    /** @param weekly carga académica de la semana (puede ser null: componentes neutros). */
    public static EnergyScore compute(DailyCheckIn checkIn, WeeklyAcademicLoad weekly) {
        double dailyEnergy = checkIn.energy() / 5.0 * 100;
        double sleep = checkIn.sleep() / 5.0 * 100;
        double recovery = (5 - checkIn.soreness()) / 4.0 * 100;
        double cognitive = weekly == null ? 50.0
                : clamp01(1.0 - weekly.realStudyHours() / STUDY_HOURS_SATURATION) * 100;
        double stress = (10.0 - (weekly == null ? 5 : weekly.stressLevel())) / 10.0 * 100;

        double base = dailyEnergy * 0.30 + sleep * 0.25 + recovery * 0.20 + cognitive * 0.15 + stress * 0.10;
        double sleepGate = checkIn.sleep() <= 1 ? 0.40 : checkIn.sleep() == 2 ? 0.70 : 1.0;
        double sorenessGate = checkIn.soreness() >= 4 ? 0.60 : checkIn.soreness() == 3 ? 0.85 : 1.0;
        double energyGate = checkIn.energy() <= 1 ? 0.50 : checkIn.energy() == 2 ? 0.75 : 1.0;
        double score = Math.max(0, Math.min(100, base * sleepGate * sorenessGate * energyGate));
        return new EnergyScore(score, base, dailyEnergy, sleep, recovery, cognitive, stress, sleepGate,
                sorenessGate, energyGate);
    }

    private static double clamp01(double v) {
        return Math.max(0, Math.min(1, v));
    }
}
