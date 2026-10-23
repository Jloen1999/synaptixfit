package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.MindMap;
import com.synaptixfit.domain.model.academic.Note;
import java.util.UUID;

/** Guarda un resultado generado como apunte (el mapa mental se serializa a Markdown). */
public interface SaveArtifactAsNoteUseCase {

    record Command(UUID userId, UUID subjectId, String title, String markdown, MindMap mindMap) {}

    Note saveAsNote(Command command);
}
