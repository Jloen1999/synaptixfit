package com.synaptixfit.application.port.input.catalog;

import com.synaptixfit.domain.model.catalog.CatalogSubjectFilter;
import com.synaptixfit.domain.model.catalog.UserCatalogSubject;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.UUID;

/**
 * Asignaturas del catálogo de las carreras del usuario (selector de asignaturas), indicando cuáles
 * ya tiene como asignatura propia y si está activa.
 */
public interface ListMyCatalogSubjectsUseCase {

    PageResult<UserCatalogSubject> listMyCatalogSubjects(UUID userId, CatalogSubjectFilter filter, PageRequest page);
}
