package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.user.ExperienceChange;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Registra un día de rutina entrenado sin la app (hoy o hasta 7 días antes): completa el día y
 * guarda carga, XP, retos y bloque del calendario en esa fecha.
 */
public interface LogPastRoutineSessionUseCase {

    Result logPast(Command command);

    record Command(UUID userId, UUID routineId, UUID dayId, LocalDate date, int durationMinutes, int rpe) {
    }

    record Result(TrainingSession session, ExperienceChange experience) {
    }
}
