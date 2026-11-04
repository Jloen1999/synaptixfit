package com.synaptixfit.domain.exception.privacy;

import com.synaptixfit.domain.exception.ConflictException;

/** Se intentó aceptar una versión de la política que ya no es la vigente: hay que leer la nueva. */
public class LegalVersionOutdatedException extends ConflictException {

    public LegalVersionOutdatedException() {
        super("LEGAL_VERSION_OUTDATED", "The accepted legal version is not the current one");
    }
}
