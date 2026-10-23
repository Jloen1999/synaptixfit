package com.synaptixfit.application.port.input.planner;

import java.util.UUID;

/** Pone en privado todos los planes semanales del usuario (al pasar su perfil a privado). Idempotente. */
public interface PrivatizeUserStudyPlansUseCase {

    /** @return número de planes que han cambiado */
    int privatizeAll(UUID userId);
}
