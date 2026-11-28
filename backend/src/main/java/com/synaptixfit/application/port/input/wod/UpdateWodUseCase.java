package com.synaptixfit.application.port.input.wod;

import com.synaptixfit.domain.model.wod.Wod;
import com.synaptixfit.domain.model.wod.WodDefinition;
import java.time.LocalDate;
import java.util.UUID;

/** Cambia la pizarra o el día de un WOD de la persona (ADR 0069). */
public interface UpdateWodUseCase {

    /** @param date día nuevo; nulo = el que tenía */
    record Command(UUID userId, UUID wodId, LocalDate date, WodDefinition definition) {
    }

    Wod updateWod(Command command);
}
