package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.shared.Visibility;
import java.util.UUID;

/** Crea un apunte (también el texto escaneado por el cliente). La asignatura, si se indica, debe ser propia. */
public interface CreateNoteUseCase {

    record Command(UUID userId, UUID subjectId, String title, String content, Visibility visibility,
                   boolean quickNote) {}

    Note createNote(Command command);
}
