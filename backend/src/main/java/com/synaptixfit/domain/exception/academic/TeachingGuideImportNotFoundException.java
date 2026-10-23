package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** La importación de plan docente no existe o es de otro usuario. */
public class TeachingGuideImportNotFoundException extends ResourceNotFoundException {

    public TeachingGuideImportNotFoundException(Object id) {
        super("TEACHING_GUIDE_IMPORT_NOT_FOUND", "Teaching guide import", id);
    }
}
