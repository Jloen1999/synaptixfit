package com.synaptixfit.application.port.input.run;

import java.util.UUID;

/** Borra una carrera: su evento del calendario (resta su XP y su carga física) y, con él, su ruta. */
public interface DeleteRunUseCase {

    void deleteRun(UUID userId, UUID blockId);
}
