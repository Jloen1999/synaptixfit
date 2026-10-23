package com.synaptixfit.application.port.input.academic;

import java.util.UUID;

/** Borra un apunte propio junto con su material de estudio y sus documentos de IA. */
public interface DeleteNoteUseCase {

    void deleteNote(UUID userId, UUID noteId);
}
