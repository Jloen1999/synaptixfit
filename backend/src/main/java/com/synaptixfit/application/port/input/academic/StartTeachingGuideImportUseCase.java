package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TeachingGuideImportView;
import java.util.UUID;

/** Registra el PDF ya subido y pide a la IA que lo analice en segundo plano. */
public interface StartTeachingGuideImportUseCase {

    record Command(UUID userId, String objectKey, String fileName, String mimeType, long sizeBytes,
                   UUID targetSubjectId) {
    }

    TeachingGuideImportView start(Command command);
}
