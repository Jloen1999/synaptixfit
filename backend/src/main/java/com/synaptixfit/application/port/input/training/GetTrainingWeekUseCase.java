package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingWeek;
import java.util.UUID;

/** La semana de entreno en curso: días entrenados, días que aún tocan y hoy (ADR 0055). */
public interface GetTrainingWeekUseCase {

    TrainingWeek trainingWeek(UUID userId);
}
