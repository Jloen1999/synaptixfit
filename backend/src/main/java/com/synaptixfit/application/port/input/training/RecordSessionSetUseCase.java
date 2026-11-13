package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import java.util.UUID;

/** Registra (o sustituye) una serie de una sesión en curso. */
public interface RecordSessionSetUseCase {

    TrainingSession recordSet(Command command);

    /**
     * Lo apuntado en la serie; tiempo y distancia, solo en ejercicios que se miden así (pueden ser nulos).
     * {@code activeSeconds}: lo que marcó el cronómetro de la serie, si se usó. ADR 0031: {@code warmup} la
     * apunta como serie de calentamiento (numeración propia, no cuenta como trabajo); {@code toFailure}, que se
     * hizo hasta no poder más; {@code exerciseId}, el ejercicio que se hizo de verdad cuando se cambió solo
     * para esta sesión («Usar hoy»; nulo: el del hueco de la rutina). {@code failedReps} nulo: las calcula el
     * servidor (objetivo − hechas, {@code PlannedExercise#missedReps}); las apps anteriores aún las mandan.
     */
    record Command(UUID userId, UUID sessionId, UUID plannedExerciseId, int setNumber, Integer repsDone,
                   Double weightKg, boolean completed, Integer failedReps, Integer durationSeconds,
                   Integer distanceMeters, Integer activeSeconds, boolean warmup, boolean toFailure,
                   UUID exerciseId) {

        public Command(UUID userId, UUID sessionId, UUID plannedExerciseId, int setNumber, Integer repsDone,
                       Double weightKg, boolean completed, Integer failedReps, Integer durationSeconds,
                       Integer distanceMeters, Integer activeSeconds) {
            this(userId, sessionId, plannedExerciseId, setNumber, repsDone, weightKg, completed, failedReps,
                    durationSeconds, distanceMeters, activeSeconds, false, false, null);
        }

        public Command(UUID userId, UUID sessionId, UUID plannedExerciseId, int setNumber, Integer repsDone,
                       Double weightKg, boolean completed, Integer failedReps, Integer durationSeconds,
                       Integer distanceMeters) {
            this(userId, sessionId, plannedExerciseId, setNumber, repsDone, weightKg, completed, failedReps,
                    durationSeconds, distanceMeters, null);
        }

        public Command(UUID userId, UUID sessionId, UUID plannedExerciseId, int setNumber, Integer repsDone,
                       Double weightKg, boolean completed, Integer failedReps) {
            this(userId, sessionId, plannedExerciseId, setNumber, repsDone, weightKg, completed, failedReps, null,
                    null, null);
        }
    }
}
