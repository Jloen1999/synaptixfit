package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.shared.Visibility;
import java.util.UUID;

/** Edita un apunte propio. Campos nulos sin cambios; detachSubject lo deja sin asignatura. */
public interface UpdateNoteUseCase {

    record Command(UUID userId, UUID noteId, String title, String content, UUID subjectId, boolean detachSubject,
                   Visibility visibility, Boolean quickNote) {}

    Note updateNote(Command command);
}
