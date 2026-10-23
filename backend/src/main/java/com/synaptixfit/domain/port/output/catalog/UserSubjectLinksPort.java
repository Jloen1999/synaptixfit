package com.synaptixfit.domain.port.output.catalog;

import com.synaptixfit.domain.model.catalog.SubjectLink;
import java.util.Collection;
import java.util.Map;
import java.util.UUID;

/** Lectura de las asignaturas propias del usuario creadas desde el catálogo (módulo académico). */
public interface UserSubjectLinksPort {

    /** Asignatura propia por id de asignatura del catálogo (solo las que existen). */
    Map<UUID, SubjectLink> findByCatalogSubjects(UUID userId, Collection<UUID> catalogSubjectIds);
}
