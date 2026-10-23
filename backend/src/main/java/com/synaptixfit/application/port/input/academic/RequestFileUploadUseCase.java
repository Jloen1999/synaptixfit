package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.FileUploadTicket;
import java.util.UUID;

/** Valida tipo y tamaño (máx. 25 MB), reserva la clave de objeto y devuelve la URL prefirmada de subida. */
public interface RequestFileUploadUseCase {

    record Command(UUID userId, UUID subjectId, String fileName, String mimeType, long sizeBytes) {}

    FileUploadTicket requestUpload(Command command);
}
