package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.TrainingSession;
import java.util.UUID;

/** Historial de sesiones; {@code completed} nulo no filtra. */
public interface ListTrainingSessionsUseCase {

    PageResult<TrainingSession> list(UUID userId, Boolean completed, PageRequest page);
}
