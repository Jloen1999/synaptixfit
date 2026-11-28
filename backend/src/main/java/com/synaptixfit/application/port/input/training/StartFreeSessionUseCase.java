package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import java.util.List;
import java.util.UUID;

/**
 * Empieza una sesión libre con su lista de ejercicios (ADR 0067). Una sola fuente por sesión: ejercicios elegidos,
 * repetir una sesión anterior o un día de una plantilla; sin ninguna, la sesión empieza vacía.
 */
public interface StartFreeSessionUseCase {

    TrainingSession startFree(Command command);

    /**
     * @param exerciseIds       ejercicios elegidos, en orden
     * @param fromSessionId     sesión propia que se repite (lo que se hizo en ella)
     * @param templateId        plantilla de rutina de la que se toma un día
     * @param templateDayNumber día de esa plantilla (1-7)
     * @param language          idioma de los nombres de la plantilla
     */
    record Command(UUID userId, List<UUID> exerciseIds, UUID fromSessionId, UUID templateId,
                   Integer templateDayNumber, String language) {
        public Command {
            exerciseIds = exerciseIds == null ? List.of() : List.copyOf(exerciseIds);
        }
    }
}
