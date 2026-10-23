package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedDay;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Lo que se envía al modelo generativo para refinar una semana tipo: perfil, contexto, semana base
 * (ejercicios con su nombre) y catálogo de candidatos para sustituciones (los 60 más afines).
 */
public record RoutineRefinementRequest(TrainingProfile profile, TrainingGoal goal, int durationWeeks,
                                       String baseName, String baseDescription, List<ProposedDay> baseDays,
                                       List<Exercise> candidates, Map<UUID, Exercise> baseExercises,
                                       AcademicContext academic, DailyCheckIn checkIn, TrainingHistory history,
                                       List<String> adjustmentReasons) {

    public RoutineRefinementRequest {
        baseDays = List.copyOf(baseDays);
        candidates = List.copyOf(candidates);
        baseExercises = Map.copyOf(baseExercises);
        adjustmentReasons = List.copyOf(adjustmentReasons == null ? List.of() : adjustmentReasons);
    }
}
