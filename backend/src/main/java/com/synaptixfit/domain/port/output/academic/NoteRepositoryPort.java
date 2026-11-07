package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.AuthoredNote;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.SharedNoteSummary;
import com.synaptixfit.domain.model.shared.AudienceScope;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.shared.Visibility;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/** Persistencia de apuntes. */
public interface NoteRepositoryPort {

    /** Filtros del listado propio: asignatura, solo notas rápidas, solo sin asignatura. */
    record Filter(UUID subjectId, boolean quickOnly, boolean unassignedOnly) {
    }

    /**
     * Filtros de los apuntes compartidos: ámbito (amigos, comunidad o todo), autor y asignatura del
     * catálogo. Nulos sin filtrar.
     */
    /** {@code folded}: texto buscado ya plegado ({@code AcademicSearch.fold}), o {@code null} sin búsqueda. */
    record SharedFilter(AudienceScope scope, UUID authorId, UUID catalogSubjectId, String folded) {

        public SharedFilter(AudienceScope scope, UUID authorId, UUID catalogSubjectId) {
            this(scope, authorId, catalogSubjectId, null);
        }
    }

    Optional<Note> findByIdAndUser(UUID id, UUID userId);

    /** Apuntes del usuario, los editados más recientemente primero. */
    PageResult<Note> findByUser(UUID userId, Filter filter, PageRequest page);

    /**
     * Resúmenes de apuntes de otros usuarios visibles para {@code viewerId} según
     * {@code EffectiveVisibility}, los editados más recientemente primero (nunca los propios).
     */
    PageResult<SharedNoteSummary> findShared(UUID viewerId, SharedFilter filter, PageRequest page);

    /**
     * Resúmenes de los apuntes propios cuya visibilidad y privacidad del perfil están las dos en
     * {@code levels} (los decide el caso de uso), opcionalmente de una asignatura del catálogo.
     */
    PageResult<SharedNoteSummary> findOwnShared(UUID userId, Set<Visibility> levels, UUID catalogSubjectId,
                                                PageRequest page);

    /** Un apunte de cualquier usuario con los datos de su autor vistos por {@code viewerId}, sin decidir nada. */
    Optional<AuthoredNote> findAuthored(UUID viewerId, UUID noteId);

    /** Apuntes del usuario compartidos con amigos o públicos. */
    List<Note> findNonPrivateByUser(UUID userId);

    Note save(Note note);

    void delete(UUID id);
}
