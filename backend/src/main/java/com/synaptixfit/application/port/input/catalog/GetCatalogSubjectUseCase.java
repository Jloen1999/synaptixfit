package com.synaptixfit.application.port.input.catalog;

import com.synaptixfit.domain.model.catalog.CatalogSubjectDetail;
import java.util.UUID;

/** Ficha completa de una asignatura del catálogo. */
public interface GetCatalogSubjectUseCase {

    CatalogSubjectDetail getSubject(UUID subjectId);
}
