package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.SubjectRef;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** Lectura de las asignaturas del usuario (tabla del módulo académico). */
public interface SubjectDirectoryPort {

    /** La asignatura si existe y es del usuario. */
    Optional<SubjectRef> findOwned(UUID userId, UUID subjectId);

    /** Asignaturas no archivadas, por nombre. */
    List<SubjectRef> findActive(UUID userId);

    /** Nombre de cada asignatura del usuario por id. */
    Map<UUID, String> namesOf(UUID userId, Collection<UUID> subjectIds);
}
