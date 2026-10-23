package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** La asignatura del catálogo no existe. */
public class CatalogSubjectNotFoundException extends ResourceNotFoundException {

    public CatalogSubjectNotFoundException(Object id) {
        super("SUBJECT_CATALOG_NOT_FOUND", "Catalog subject", id);
    }
}
