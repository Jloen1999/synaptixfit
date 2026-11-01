package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.AuthorAudience;
import java.util.UUID;

/**
 * Apunte de cualquier usuario con los datos de su autor vistos por quien lo pide, para que el caso de
 * uso decida con {@code EffectiveVisibility} si puede leerlo. Lo devuelve {@code NoteRepositoryPort}.
 */
public record AuthoredNote(Note note, String authorName, String authorAvatarUrl, UUID catalogSubjectId,
                           String catalogSubjectName, AuthorAudience audience) {
}
