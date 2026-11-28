package com.synaptixfit.application.port.input.wod;

import com.synaptixfit.domain.model.wod.WodBoard;
import java.util.UUID;

/**
 * La pizarra de hoy: el WOD de la persona o una plantilla de ejemplo, con su mejor marca y la de hoy (ADR 0069).
 */
public interface GetWodBoardUseCase {

    /** @param templateCode plantilla de ejemplo que se quiere ver en vez de la que toca (opcional) */
    WodBoard board(UUID userId, String templateCode);
}
