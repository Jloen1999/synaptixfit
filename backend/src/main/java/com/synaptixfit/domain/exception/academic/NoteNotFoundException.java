package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** El apunte no existe o no es del usuario. */
public class NoteNotFoundException extends ResourceNotFoundException {

    public NoteNotFoundException(Object id) {
        super("NOTE_NOT_FOUND", "Note", id);
    }
}
