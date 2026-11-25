package com.synaptixfit.application.port.input.social;

import java.util.UUID;

/** Retira del muro la publicación de un apunte que se ha borrado (ADR 0064). Idempotente. */
public interface RetractNotePostUseCase {

    void retractNotePost(UUID userId, UUID noteId);
}
