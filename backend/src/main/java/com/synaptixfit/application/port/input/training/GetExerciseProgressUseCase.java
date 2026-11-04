package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.ExerciseProgress;
import java.util.List;
import java.util.UUID;

/** Evolución de un ejercicio del usuario: peso máximo estimado por día para la gráfica. */
public interface GetExerciseProgressUseCase {

    List<ExerciseProgress.Point> exerciseProgress(UUID userId, UUID exerciseId);
}
