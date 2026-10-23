package com.synaptixfit.application.port.input.analytics;

import com.synaptixfit.domain.model.analytics.TrainingVolume;
import java.util.UUID;

/** Volumen semanal de entrenamiento en el periodo. */
public interface GetTrainingVolumeUseCase {

    TrainingVolume getTrainingVolume(UUID userId, String period);
}
