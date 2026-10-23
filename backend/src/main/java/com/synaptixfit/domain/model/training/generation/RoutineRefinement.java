package com.synaptixfit.domain.model.training.generation;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Respuesta (ya parseada, todavía sin validar) del modelo generativo. Los valores numéricos se
 * conservan tal cual; {@link ProposalRepair} decide cuáles se aceptan.
 *
 * @param days      ejercicios por número de día de la semana tipo
 * @param weekNames nombre por número de semana
 * @param dayNames  nombre por número de semana y de día
 */
public record RoutineRefinement(String name, String description, Map<Integer, List<RefinedExercise>> days,
                                Map<Integer, String> weekNames, Map<Integer, Map<Integer, String>> dayNames) {

    public RoutineRefinement {
        days = days == null ? Map.of() : Map.copyOf(days);
        weekNames = weekNames == null ? Map.of() : Map.copyOf(weekNames);
        dayNames = dayNames == null ? Map.of() : Map.copyOf(dayNames);
    }

    /** Ejercicio devuelto por la IA. */
    public record RefinedExercise(UUID exerciseId, Integer sets, Integer reps, Integer restSeconds, Double weightKg,
                                  Integer targetDurationSeconds, Integer distanceMeters, Integer isometricSeconds) {
    }
}
