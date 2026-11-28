package com.synaptixfit.application.port.input.wod;

import com.synaptixfit.domain.model.wod.Wod;
import com.synaptixfit.domain.model.wod.WodDefinition;
import java.time.LocalDate;
import java.util.UUID;

/** Crea un WOD de la persona, desde cero o partiendo de una plantilla de ejemplo (ADR 0069). */
public interface CreateWodUseCase {

    /**
     * @param date         día del WOD; por defecto, hoy
     * @param templateCode plantilla de la que parte (opcional)
     */
    record Command(UUID userId, LocalDate date, String templateCode, WodDefinition definition) {
    }

    Wod createWod(Command command);
}
