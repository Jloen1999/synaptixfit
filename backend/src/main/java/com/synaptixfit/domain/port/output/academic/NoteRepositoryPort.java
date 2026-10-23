package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.SharedNote;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de apuntes. */
public interface NoteRepositoryPort {

    /** Filtros del listado propio: asignatura, solo notas rápidas, solo sin asignatura. */
    record Filter(UUID subjectId, boolean quickOnly, boolean unassignedOnly) {
    }

    Optional<Note> findByIdAndUser(UUID id, UUID userId);

    /** Apuntes del usuario, los editados más recientemente primero. */
    PageResult<Note> findByUser(UUID userId, Filter filter, PageRequest page);

    /**
     * Apuntes de otros usuarios visibles para {@code viewerId}: públicos, o de amigos con amistad
     * aceptada. Excluye autores eliminados o silenciados (shadowban).
     */
    PageResult<SharedNote> findSharedWith(UUID viewerId, PageRequest page);

    /** Apuntes del usuario compartidos con amigos o públicos. */
    List<Note> findNonPrivateByUser(UUID userId);

    Note save(Note note);

    void delete(UUID id);
}
