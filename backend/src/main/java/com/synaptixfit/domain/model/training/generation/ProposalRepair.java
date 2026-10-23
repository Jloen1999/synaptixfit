package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedDay;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedExercise;
import com.synaptixfit.domain.model.training.generation.RoutineRefinement.RefinedExercise;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Valida y repara la salida de la IA contra la semana base (nunca se confía en ella): conserva
 * los mismos días y número de ejercicios; un ejercicio sustituido solo se acepta si existe, está
 * activo y es apto para el usuario; cada parámetro fuera de rango se sustituye por el de la base;
 * los pesos por serie, la duración, la distancia y el isométrico de la base se preservan cuando
 * la IA no los da.
 */
public final class ProposalRepair {

    private ProposalRepair() {
    }

    public static List<ProposedDay> repair(List<ProposedDay> base, Map<Integer, List<RefinedExercise>> ai,
                                           Map<UUID, Exercise> catalog, TrainingProfile profile) {
        List<ProposedDay> result = new ArrayList<>();
        for (ProposedDay day : base) {
            List<RefinedExercise> aiDay = ai.getOrDefault(day.dayNumber(), List.of());
            List<ProposedExercise> repaired = new ArrayList<>();
            for (int i = 0; i < day.exercises().size(); i++) {
                ProposedExercise b = day.exercises().get(i);
                repaired.add(i < aiDay.size() ? repairOne(aiDay.get(i), b, catalog, profile) : b);
            }
            result.add(day.withExercises(repaired));
        }
        return result;
    }

    static ProposedExercise repairOne(RefinedExercise ia, ProposedExercise base, Map<UUID, Exercise> catalog,
                                      TrainingProfile profile) {
        if (ia == null || ia.exerciseId() == null) {
            return base;
        }
        Exercise exercise = catalog.get(ia.exerciseId());
        if (exercise == null || !ExerciseEligibility.eligible(exercise, profile)) {
            return base;
        }
        ExerciseParameters b = base.parameters();
        int sets = inRange(ia.sets(), 1, 10) ? ia.sets() : b.sets();
        int reps = inRange(ia.reps(), 1, 100) ? ia.reps() : b.reps();
        int rest = inRange(ia.restSeconds(), 15, 600) ? ia.restSeconds() : b.restSeconds();
        Double weight = ia.weightKg() != null && ia.weightKg() >= 0 && ia.weightKg() <= 300 ? ia.weightKg() : b.weightKg();
        Integer duration = inRange(ia.targetDurationSeconds(), 30, 7200) ? ia.targetDurationSeconds() : b.targetDurationSeconds();
        Integer distance = inRange(ia.distanceMeters(), 50, 42_195) ? ia.distanceMeters() : b.distanceMeters();
        Integer iso = inRange(ia.isometricSeconds(), 5, 300) ? ia.isometricSeconds() : b.isometricSeconds();
        List<Double> perSet = sets == b.sets() && java.util.Objects.equals(weight, b.weightKg())
                ? b.weightsKg()
                : weight != null && weight > 0 ? ProgressionCalculator.warmupWeights(weight, sets) : null;
        return new ProposedExercise(exercise.id(), exercise.name(),
                ExerciseParameters.clamped(sets, reps, rest, weight, perSet, duration, distance, iso));
    }

    private static boolean inRange(Integer v, int min, int max) {
        return v != null && v >= min && v <= max;
    }
}
