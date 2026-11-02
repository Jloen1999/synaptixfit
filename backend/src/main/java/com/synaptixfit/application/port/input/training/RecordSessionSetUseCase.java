package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import java.util.UUID;

/** Registra (o sustituye) una serie de una sesión en curso. */
public interface RecordSessionSetUseCase {

    TrainingSession recordSet(Command command);

    /**
     * Lo apuntado en la serie; tiempo y distancia, solo en ejercicios que se miden así (pueden ser nulos).
     * {@code activeSeconds}: lo que marcó el cronómetro de la serie, si se usó.
     */
    record Command(UUID userId, UUID sessionId, UUID plannedExerciseId, int setNumber, Integer repsDone,
                   Double weightKg, boolean completed, int failedReps, Integer durationSeconds,
                   Integer distanceMeters, Integer activeSeconds) {

        public Command(UUID userId, UUID sessionId, UUID plannedExerciseId, int setNumber, Integer repsDone,
                       Double weightKg, boolean completed, int failedReps, Integer durationSeconds,
                       Integer distanceMeters) {
            this(userId, sessionId, plannedExerciseId, setNumber, repsDone, weightKg, completed, failedReps,
                    durationSeconds, distanceMeters, null);
        }

        public Command(UUID userId, UUID sessionId, UUID plannedExerciseId, int setNumber, Integer repsDone,
                       Double weightKg, boolean completed, int failedReps) {
            this(userId, sessionId, plannedExerciseId, setNumber, repsDone, weightKg, completed, failedReps, null,
                    null, null);
        }
    }
}
