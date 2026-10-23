package com.synaptixfit.domain.model.shared;

import com.synaptixfit.domain.exception.FieldValidationException;

/** Petición de página (base 0). */
public record PageRequest(int page, int size) {

    public static final int MAX_SIZE = 100;

    public PageRequest {
        if (page < 0) {
            throw new FieldValidationException("page", "MUST_BE_POSITIVE_OR_ZERO", "page must be >= 0");
        }
        if (size < 1 || size > MAX_SIZE) {
            throw new FieldValidationException("size", "OUT_OF_RANGE", "size must be between 1 and " + MAX_SIZE);
        }
    }

    public long offset() {
        return (long) page * size;
    }
}
