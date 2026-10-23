package com.synaptixfit.application.port.input.challenge;

import java.util.UUID;

/** El usuario ha pasado a perfil privado: todos sus retos pasan a privados. */
public interface HideUserChallengesUseCase {

    int hideUserChallenges(UUID userId);
}
