package com.synaptixfit.domain.exception;

import java.util.Objects;

/**
 * Recurso inexistente o ajeno. Un recurso de otro usuario se trata como inexistente para no
 * revelar su existencia.
 */
public class ResourceNotFoundException extends NotFoundException {

    public ResourceNotFoundException(String code, String resource, Object id) {
        super(code, resource + " " + Objects.toString(id) + " not found");
    }
}
