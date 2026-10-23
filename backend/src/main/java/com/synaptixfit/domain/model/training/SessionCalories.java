package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.neuro.ExerciseEnergy;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Estimación del gasto calórico de una sesión con MET por ejercicio ({@link ExerciseEnergy}).
 *
 * <p>Por cada ejercicio planificado del día: tiempo de trabajo = duración real registrada (total del
 * ejercicio) o, si falta, duración objetivo × series, tiempo isométrico × series o, para ejercicios
 * por repeticiones, {@value #SECONDS_PER_REP} s por repetición × repeticiones × series; más el
 * descanso entre series a MET de reposo. Si la estimación supera la duración real de la sesión se
 * escala a ella. Sin ejercicios planificados (sesión libre) se usa MET 6 durante toda la sesión.
 *
 * <p>Corrige dos fallos heredados: la duración real se multiplicaba otra vez por las series y los
 * ejercicios por repeticiones (la mayoría) no sumaban calorías de trabajo.
 */
public final class SessionCalories {

    static final int SECONDS_PER_REP = 3;
    static final double FREE_SESSION_MET = 6.0;

    private SessionCalories() {
    }

    public static double estimate(List<PlannedExercise> planned, Map<UUID, Integer> realDurations,
                                  Double weightKg, long sessionSeconds) {
        if (planned == null || planned.isEmpty()) {
            return ExerciseEnergy.calories(FREE_SESSION_MET, weightKg, sessionSeconds);
        }
        double workKcal = 0;
        double restKcal = 0;
        long estimatedSeconds = 0;
        for (PlannedExercise p : planned) {
            ExerciseParameters params = p.parameters();
            long work = workSeconds(p, realDurations == null ? null : realDurations.get(p.id()));
            long rest = (long) params.restSeconds() * Math.max(0, params.sets() - 1);
            workKcal += ExerciseEnergy.calories(p.exercise().effectiveMet(), weightKg, work);
            restKcal += ExerciseEnergy.restCalories(weightKg, rest);
            estimatedSeconds += work + rest;
        }
        double total = workKcal + restKcal;
        if (sessionSeconds > 0 && estimatedSeconds > sessionSeconds) {
            total = total * sessionSeconds / estimatedSeconds;
        }
        return total;
    }

    private static long workSeconds(PlannedExercise p, Integer realSeconds) {
        if (realSeconds != null && realSeconds > 0) {
            return realSeconds;
        }
        ExerciseParameters params = p.parameters();
        if (params.targetDurationSeconds() != null) {
            return (long) params.targetDurationSeconds() * params.sets();
        }
        if (params.isometricSeconds() != null) {
            return (long) params.isometricSeconds() * params.sets();
        }
        return (long) SECONDS_PER_REP * params.reps() * params.sets();
    }
}
