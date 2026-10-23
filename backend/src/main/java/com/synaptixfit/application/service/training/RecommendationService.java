package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.ApplyRecommendationUseCase;
import com.synaptixfit.application.port.input.training.DiscardRecommendationUseCase;
import com.synaptixfit.application.port.input.training.ListRecommendationsUseCase;
import com.synaptixfit.domain.exception.training.RecommendationNotFoundException;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.ExerciseAdjustment;
import com.synaptixfit.domain.model.training.Recommendation;
import com.synaptixfit.domain.port.output.training.RecommendationRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import java.util.UUID;

/**
 * Sugerencias pendientes. Aplicar copia los ajustes a los ejercicios planificados que sigan
 * existiendo en la rutina del usuario (los que ya no existan se ignoran) y la marca como aplicada.
 */
public class RecommendationService implements ListRecommendationsUseCase, ApplyRecommendationUseCase,
        DiscardRecommendationUseCase {

    private final RecommendationRepositoryPort recommendations;
    private final RoutineRepositoryPort routines;

    public RecommendationService(RecommendationRepositoryPort recommendations, RoutineRepositoryPort routines) {
        this.recommendations = recommendations;
        this.routines = routines;
    }

    @Override
    public PageResult<Recommendation> list(UUID userId, Boolean applied, PageRequest page) {
        return recommendations.findByUser(userId, applied, page);
    }

    @Override
    public Recommendation apply(UUID userId, UUID recommendationId) {
        Recommendation recommendation = owned(userId, recommendationId);
        recommendation.markApplied();
        if (recommendation.routineId() != null && !recommendation.adjustments().isEmpty()) {
            routines.findById(recommendation.routineId()).filter(r -> r.isOwnedBy(userId)).ifPresent(routine -> {
                boolean changed = false;
                for (ExerciseAdjustment adjustment : recommendation.adjustments()) {
                    if (routine.findPlannedExercise(adjustment.plannedExerciseId()).isPresent()) {
                        routine.updateExercise(adjustment.plannedExerciseId(), adjustment.parameters());
                        changed = true;
                    }
                }
                if (changed) {
                    routines.save(routine);
                }
            });
        }
        return recommendations.save(recommendation);
    }

    @Override
    public void discard(UUID userId, UUID recommendationId) {
        recommendations.delete(owned(userId, recommendationId).id());
    }

    private Recommendation owned(UUID userId, UUID id) {
        return recommendations.findById(id).filter(r -> r.isOwnedBy(userId))
                .orElseThrow(() -> new RecommendationNotFoundException(id));
    }
}
