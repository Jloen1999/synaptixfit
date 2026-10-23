package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.Note;
import java.util.UUID;

/** Detalle de un apunte propio. */
public interface GetNoteUseCase {

    Note getNote(UUID userId, UUID noteId);
}
