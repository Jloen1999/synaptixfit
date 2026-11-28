package com.synaptixfit.application.port.input.wod;

import java.util.UUID;

/** Borra un WOD de la persona con sus marcas; las actividades ya apuntadas se quedan (ADR 0069). */
public interface DeleteWodUseCase {

    void deleteWod(UUID userId, UUID wodId);
}
