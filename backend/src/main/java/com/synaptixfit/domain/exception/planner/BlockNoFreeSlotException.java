package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.ConflictException;

/** No hay un hueco libre de la duración del bloque en los próximos días para reprogramarlo. */
public class BlockNoFreeSlotException extends ConflictException {

    public BlockNoFreeSlotException() {
        super("BLOCK_NO_FREE_SLOT", "There is no free slot to reschedule the block in the coming days");
    }
}
