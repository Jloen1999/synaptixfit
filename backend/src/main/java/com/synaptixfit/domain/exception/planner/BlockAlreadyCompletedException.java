package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Un bloque completado no cambia de horario (su experiencia depende de la duración). */
public class BlockAlreadyCompletedException extends BusinessRuleException {

    public BlockAlreadyCompletedException() {
        super("BLOCK_COMPLETED_LOCKED", "A completed block cannot be moved or resized; unmark it first");
    }
}
