package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Lo que una persona tiene «Con amigos»: retos (en marcha o acabados hace poco), rachas y entrenos de hoy. */
public interface ListTogetherUseCase {

    TogetherOverview overview(UUID userId, String language);
}
