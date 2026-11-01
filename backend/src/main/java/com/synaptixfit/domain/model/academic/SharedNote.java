package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Visibility;
import java.util.UUID;

/**
 * Apunte (completo) que un usuario puede leer aunque no sea suyo, con su autor y la asignatura del
 * catálogo a la que pertenece, si la tiene. Lo devuelve {@code GetSharedNoteUseCase}.
 *
 * @param note                el apunte
 * @param catalogSubjectId    asignatura del plan de estudios (no la asignatura privada del autor) o {@code null}
 * @param catalogSubjectName  nombre de esa asignatura del catálogo
 * @param visibility          visibilidad efectiva: la más restrictiva entre la del apunte y la del perfil
 */
public record SharedNote(Note note, String authorName, String authorAvatarUrl, UUID catalogSubjectId,
                         String catalogSubjectName, Visibility visibility) {
}
