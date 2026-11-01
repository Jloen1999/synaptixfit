package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.Note;
import java.util.UUID;

/**
 * Guarda una copia privada de un apunte compartido visible en los apuntes del usuario, en su asignatura
 * equivalente (la misma del catálogo) si la tiene.
 */
public interface CopySharedNoteUseCase {

    Note copySharedNote(UUID userId, UUID noteId);
}
