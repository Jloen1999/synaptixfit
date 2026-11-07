package com.synaptixfit.application.port.input.run;

import com.synaptixfit.domain.model.run.RunDetail;
import java.util.UUID;

/** Detalle de una carrera del usuario: cifras, tramos por km y ruta para dibujarla. */
public interface GetRunUseCase {

    RunDetail getRun(UUID userId, UUID blockId);
}
