package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.Subject;
import java.util.List;
import java.util.UUID;

/** Crea (o reactiva si estaban archivadas) asignaturas del usuario a partir de asignaturas del catálogo. */
public interface CreateSubjectsFromCatalogUseCase {

    List<Subject> createFromCatalog(UUID userId, List<UUID> catalogSubjectIds);
}
