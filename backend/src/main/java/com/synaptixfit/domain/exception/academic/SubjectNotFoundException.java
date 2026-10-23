package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** La asignatura no existe o no es del usuario. */
public class SubjectNotFoundException extends ResourceNotFoundException {

    public SubjectNotFoundException(Object id) {
        super("SUBJECT_NOT_FOUND", "Subject", id);
    }
}
