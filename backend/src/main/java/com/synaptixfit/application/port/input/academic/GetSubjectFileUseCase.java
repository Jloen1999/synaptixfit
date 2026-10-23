package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SubjectFile;
import java.util.UUID;

/** Metadatos de un archivo propio. */
public interface GetSubjectFileUseCase {

    SubjectFile getFile(UUID userId, UUID fileId);
}
