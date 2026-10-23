package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Recommendation;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.user.ExperienceChange;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Finaliza una sesión: calorías, día completado, experiencia, evento y sugerencias. */
public interface FinishTrainingSessionUseCase {

    Result finish(Command command);

    /** {@code sets} se registran antes de finalizar; {@code realDurations} por ejercicio planificado (segundos). */
    record Command(UUID userId, UUID sessionId, long durationSeconds, int rpe, Map<UUID, Integer> realDurations,
                   List<RecordSessionSetUseCase.Command> sets) {
    }

    record Result(TrainingSession session, ExperienceChange experience, List<Recommendation> recommendations) {
    }
}
