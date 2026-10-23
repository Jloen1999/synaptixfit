package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ConflictException;

/** La importación aún se está analizando (o falló) y no se puede aplicar ni reintentar todavía. */
public class TeachingGuideImportNotReadyException extends ConflictException {

    public TeachingGuideImportNotReadyException(Object id) {
        super("TEACHING_GUIDE_IMPORT_NOT_READY", "Teaching guide import " + id + " is not ready");
    }
}
