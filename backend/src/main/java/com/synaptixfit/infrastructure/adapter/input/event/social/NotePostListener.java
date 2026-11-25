package com.synaptixfit.infrastructure.adapter.input.event.social;

import com.synaptixfit.application.port.input.social.RetractNotePostUseCase;
import com.synaptixfit.domain.event.academic.NoteDeleted;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/** Al borrar un apunte ({@link NoteDeleted}) retira su publicación del muro, si la tenía (ADR 0064). Idempotente. */
@Component
public class NotePostListener {

    private final RetractNotePostUseCase retract;

    public NotePostListener(RetractNotePostUseCase retract) {
        this.retract = retract;
    }

    @EventListener
    public void on(NoteDeleted event) {
        retract.retractNotePost(event.userId(), event.noteId());
    }
}
