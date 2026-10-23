package com.synaptixfit.application.port.input.catalog;

import com.synaptixfit.domain.model.catalog.CatalogSubject;
import com.synaptixfit.domain.model.catalog.CatalogSubjectFilter;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.UUID;

/** Plan de estudios de una carrera, filtrable y paginado. */
public interface SearchCatalogSubjectsUseCase {

    PageResult<CatalogSubject> searchSubjects(UUID degreeId, CatalogSubjectFilter filter, PageRequest page);
}
