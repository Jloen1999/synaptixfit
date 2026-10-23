package com.synaptixfit.application.port.input.academic;

import java.util.UUID;

/** Borra un archivo propio (objeto y metadatos) con su material de estudio y documentos de IA. */
public interface DeleteSubjectFileUseCase {

    void deleteFile(UUID userId, UUID fileId);
}
