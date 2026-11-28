package com.synaptixfit.application.port.input.wod;

import com.synaptixfit.domain.model.wod.WodDefinition;
import com.synaptixfit.domain.model.wod.WodDivision;
import com.synaptixfit.domain.model.wod.WodMark;
import com.synaptixfit.domain.model.wod.WodScoreType;
import java.util.UUID;

/**
 * Guarda la marca de un WOD y la apunta como actividad (deporte WOD), así cuenta para la racha, la XP, la carga y los
 * retos como cualquier otra (ADR 0069).
 */
public interface SaveWodResultUseCase {

    /**
     * @param wodId           WOD de la persona; nulo si la marca es de una plantilla de ejemplo aún sin usar
     * @param templateCode    plantilla de la que sale la pizarra (solo sin {@code wodId})
     * @param definition      la pizarra tal como se hizo (solo sin {@code wodId}): el WOD se crea con ella
     * @param scoreType       nulo = el que toca por el formato; solo se admite ese o {@code LOAD}
     * @param durationSeconds lo que duró de verdad (cronómetro); nulo si se apunta sin cronómetro
     * @param effort          esfuerzo percibido (1-10); nulo = el habitual de un WOD
     */
    record Command(UUID userId, UUID wodId, String templateCode, WodDefinition definition, WodDivision division,
                   WodScoreType scoreType, int value, Integer extraReps, boolean capped, Integer durationSeconds,
                   Integer effort) {
    }

    /** La marca guardada, con {@code best} si es la mejor de ese WOD en su división. */
    WodMark saveResult(Command command);
}
