package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.PendingDay;
import java.util.Optional;
import java.util.UUID;

/** Próximo día pendiente de la rutina activa más reciente (vacío si no hay). */
public interface GetPendingTrainingDayUseCase {

    Optional<PendingDay> pendingDay(UUID userId);
}
