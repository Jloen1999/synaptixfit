package com.synaptixfit.domain.exception.catalog;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** Centro del catálogo inexistente. */
public class CenterNotFoundException extends ResourceNotFoundException {

    public CenterNotFoundException(UUID id) {
        super("CATALOG_CENTER_NOT_FOUND", "Center", id);
    }
}
