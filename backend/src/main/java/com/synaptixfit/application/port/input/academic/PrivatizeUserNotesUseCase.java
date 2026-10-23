package com.synaptixfit.application.port.input.academic;

import java.util.UUID;

/** Pone en privado todos los apuntes del usuario (al pasar su perfil a privado). Idempotente. */
public interface PrivatizeUserNotesUseCase {

    /** @return número de apuntes que han cambiado */
    int privatizeAll(UUID userId);
}
