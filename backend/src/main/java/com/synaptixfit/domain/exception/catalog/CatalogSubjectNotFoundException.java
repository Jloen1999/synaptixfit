package com.synaptixfit.domain.exception.catalog;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** Asignatura del catálogo inexistente. */
public class CatalogSubjectNotFoundException extends ResourceNotFoundException {

    public CatalogSubjectNotFoundException(UUID id) {
        super("CATALOG_SUBJECT_NOT_FOUND", "CatalogSubject", id);
    }
}
