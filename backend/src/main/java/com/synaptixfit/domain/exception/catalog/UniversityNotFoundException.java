package com.synaptixfit.domain.exception.catalog;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** Universidad del catálogo inexistente. */
public class UniversityNotFoundException extends ResourceNotFoundException {

    public UniversityNotFoundException(UUID id) {
        super("CATALOG_UNIVERSITY_NOT_FOUND", "University", id);
    }
}
