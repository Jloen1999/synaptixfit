package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.domain.model.training.AdjustmentReason;
import com.synaptixfit.domain.model.training.ExerciseAdjustment;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.Recommendation;
import com.synaptixfit.domain.model.training.RecommendationType;
import com.synaptixfit.infrastructure.adapter.input.rest.support.LocalizedNames;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** DTOs de las sugerencias de entrenamiento. */
public final class RecommendationDtos {

    private RecommendationDtos() {
    }

    /**
     * Parámetros propuestos para un ejercicio planificado; {@code before}, los que tenía (nulo en
     * sugerencias antiguas) y {@code reasonCode}, por qué cambia.
     */
    public record AdjustmentResponse(UUID plannedExerciseId, UUID exerciseId, String exerciseName, String reason,
                                     int sets, int reps, int restSeconds, Double weightKg, List<Double> weightsKg,
                                     Integer targetDurationSeconds, Integer distanceMeters, Integer isometricSeconds,
                                     List<Integer> repsPerSet, List<Integer> isometricSecondsPerSet,
                                     AdjustmentReason reasonCode, ParametersResponse before) {
        static AdjustmentResponse from(ExerciseAdjustment a) {
            ExerciseParameters p = a.parameters();
            return new AdjustmentResponse(a.plannedExerciseId(), a.exerciseId(),
                    LocalizedNames.exercise(a.exerciseId(), a.exerciseName()), a.reason(), p.sets(),
                    p.reps(), p.restSeconds(), p.weightKg(), p.weightsKg(), p.targetDurationSeconds(),
                    p.distanceMeters(), p.isometricSeconds(), p.repsPerSet(), p.isometricSecondsPerSet(),
                    a.reasonCode(), a.before() == null ? null : ParametersResponse.from(a.before()));
        }
    }

    /** Parámetros de un ejercicio planificado (lo que había antes de la sugerencia). */
    public record ParametersResponse(int sets, int reps, int restSeconds, Double weightKg,
                                     Integer targetDurationSeconds, Integer distanceMeters, Integer isometricSeconds) {
        static ParametersResponse from(ExerciseParameters p) {
            return new ParametersResponse(p.sets(), p.reps(), p.restSeconds(), p.weightKg(), p.targetDurationSeconds(),
                    p.distanceMeters(), p.isometricSeconds());
        }
    }

    public record RecommendationResponse(UUID id, RecommendationType type, String title, String description,
                                         UUID exerciseId, UUID routineId, boolean applied, Instant createdAt,
                                         List<AdjustmentResponse> adjustments, Map<String, Object> details) {
        public static RecommendationResponse from(Recommendation r) {
            return new RecommendationResponse(r.id(), r.type(), r.title(), r.description(), r.exerciseId(),
                    r.routineId(), r.applied(), r.createdAt(),
                    r.adjustments().stream().map(AdjustmentResponse::from).toList(), r.details());
        }
    }
}
