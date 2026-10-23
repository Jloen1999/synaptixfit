package com.synaptixfit.domain.model.academic;

/** Apunte de otro usuario visible para el usuario actual (público o de un amigo), con su autor. */
public record SharedNote(Note note, String authorName, String authorAvatarUrl) {
}
