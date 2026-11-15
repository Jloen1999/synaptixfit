package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/**
 * El enlace de la rutina no existe, caducó, se revocó o su rutina ya no está (ADR 0043). Todos dan lo mismo: así no
 * se puede saber si un token existió.
 */
public class RoutineShareLinkNotFoundException extends ResourceNotFoundException {

    public RoutineShareLinkNotFoundException() {
        super("ROUTINE_SHARE_LINK_NOT_FOUND", "RoutineShareLink", "token");
    }
}
