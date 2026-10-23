package com.synaptixfit.application.port.input.training;

import java.util.UUID;

/** Pone en privado todas las rutinas del usuario (al pasar su perfil a privado). */
public interface PrivatizeUserRoutinesUseCase {

    int privatizeAll(UUID userId);
}
