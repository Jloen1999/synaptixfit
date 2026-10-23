package com.synaptixfit.domain.exception.catalog;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** Carrera del catálogo inexistente. */
public class DegreeNotFoundException extends ResourceNotFoundException {

    public DegreeNotFoundException(UUID id) {
        super("CATALOG_DEGREE_NOT_FOUND", "Degree", id);
    }
}
