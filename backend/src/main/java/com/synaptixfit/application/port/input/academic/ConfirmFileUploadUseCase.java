package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SubjectFile;
import java.util.UUID;

/** Registra los metadatos de un archivo ya subido con la URL prefirmada. */
public interface ConfirmFileUploadUseCase {

    record Command(UUID userId, UUID subjectId, String objectKey, String fileName, String mimeType,
                   long sizeBytes) {}

    SubjectFile confirmUpload(Command command);
}
