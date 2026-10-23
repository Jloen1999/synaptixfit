package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.user.ExperienceChange;
import java.util.UUID;

/** Desmarca una sesión finalizada: revierte el día, resta la experiencia otorgada y avisa. */
public interface UnmarkTrainingSessionUseCase {

    Result unmark(UUID userId, UUID sessionId);

    record Result(TrainingSession session, ExperienceChange experience) {
    }
}
