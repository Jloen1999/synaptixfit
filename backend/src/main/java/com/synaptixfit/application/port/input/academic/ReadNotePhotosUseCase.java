package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.NotePhoto;
import com.synaptixfit.domain.model.academic.ScannedNoteDraft;
import java.util.List;
import java.util.UUID;

/**
 * Convierte fotos de apuntes en papel en un borrador de apunte para revisar. No guarda nada: el
 * apunte se crea después con el texto ya corregido, como cualquier otro ({@code POST /notes}).
 */
public interface ReadNotePhotosUseCase {

    record Command(UUID userId, List<NotePhoto> photos) {
    }

    ScannedNoteDraft read(Command command);
}
