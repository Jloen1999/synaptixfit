package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.PendingDay;
import java.util.Optional;
import java.util.UUID;

/**
 * Próximo día de la rutina en curso con su fecha prevista, retraso y posición en la semana (regla
 * única de {@code RoutineSchedule}); vacío si no hay rutina en curso o no le quedan días.
 */
public interface GetPendingTrainingDayUseCase {

    Optional<PendingDay> pendingDay(UUID userId);
}
