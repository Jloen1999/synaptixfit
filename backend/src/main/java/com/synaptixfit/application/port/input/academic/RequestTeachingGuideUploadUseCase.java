package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.FileUploadTicket;
import java.util.UUID;

/** Reserva la clave y firma la subida del PDF de un plan docente (aún sin asignatura). */
public interface RequestTeachingGuideUploadUseCase {

    FileUploadTicket requestUpload(UUID userId, String fileName, String mimeType, long sizeBytes);
}
