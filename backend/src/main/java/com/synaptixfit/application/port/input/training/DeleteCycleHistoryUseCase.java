package com.synaptixfit.application.port.input.training;

import java.util.UUID;

/** Borra todos los días apuntados del ciclo; el seguimiento sigue como estaba. */
public interface DeleteCycleHistoryUseCase {

    void deleteAll(UUID userId);
}
