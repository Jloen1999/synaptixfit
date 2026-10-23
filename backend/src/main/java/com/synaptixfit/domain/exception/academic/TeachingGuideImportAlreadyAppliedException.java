package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ConflictException;

/** La importación ya se aplicó a una asignatura; para cambiarla hay que importar de nuevo. */
public class TeachingGuideImportAlreadyAppliedException extends ConflictException {

    public TeachingGuideImportAlreadyAppliedException(Object id) {
        super("TEACHING_GUIDE_IMPORT_ALREADY_APPLIED", "Teaching guide import " + id + " was already applied");
    }
}
