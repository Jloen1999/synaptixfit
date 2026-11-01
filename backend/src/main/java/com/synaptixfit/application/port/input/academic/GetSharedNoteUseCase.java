package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SharedNote;
import java.util.UUID;

/** Lee un apunte completo de otro usuario (o propio) si la regla de visibilidad lo permite; si no, 404. */
public interface GetSharedNoteUseCase {

    SharedNote getSharedNote(UUID userId, UUID noteId);
}
