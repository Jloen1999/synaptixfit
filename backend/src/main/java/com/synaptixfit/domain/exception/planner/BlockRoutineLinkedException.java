package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.ConflictException;

/**
 * Un bloque que refleja un día de rutina no se marca ni se desmarca a mano: sigue a la sesión de
 * entrenamiento de ese día (se empieza la sesión o se registra como sesión pasada).
 */
public class BlockRoutineLinkedException extends ConflictException {

    public BlockRoutineLinkedException() {
        super("BLOCK_ROUTINE_LINKED", "A block linked to a routine day follows its training session");
    }
}
