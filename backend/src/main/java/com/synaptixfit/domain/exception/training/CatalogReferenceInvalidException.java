package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.InvalidInputException;

/** Algún músculo, parte del cuerpo o equipamiento no existe. */
public class CatalogReferenceInvalidException extends InvalidInputException {

    public CatalogReferenceInvalidException() {
        super("EXERCISE_CATALOG_REFERENCE_INVALID", "Unknown muscle, body part or equipment id");
    }
}
