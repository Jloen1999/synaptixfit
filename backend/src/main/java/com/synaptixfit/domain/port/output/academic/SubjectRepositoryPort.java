package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.Subject;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de las asignaturas del usuario. */
public interface SubjectRepositoryPort {

    /** Conteo de apuntes y archivos de una asignatura. */
    record ContentCount(long notes, long files) {
    }

    Optional<Subject> findByIdAndUser(UUID id, UUID userId);

    /** Asignaturas del usuario ordenadas por nombre; {@code archived} nulo devuelve todas. */
    List<Subject> findByUser(UUID userId, Boolean archived);

    List<Subject> findByUserAndCatalogIds(UUID userId, Collection<UUID> catalogSubjectIds);

    Map<UUID, ContentCount> countContents(UUID userId, Collection<UUID> subjectIds);

    Subject save(Subject subject);

    void delete(UUID id);
}
