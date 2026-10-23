package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** El archivo no existe o no es del usuario. */
public class SubjectFileNotFoundException extends ResourceNotFoundException {

    public SubjectFileNotFoundException(Object id) {
        super("FILE_NOT_FOUND", "File", id);
    }
}
