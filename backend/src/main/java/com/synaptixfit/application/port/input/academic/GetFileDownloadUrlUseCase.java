package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SignedUrl;
import java.util.UUID;

/** URL prefirmada de descarga de un archivo propio. */
public interface GetFileDownloadUrlUseCase {

    SignedUrl downloadUrl(UUID userId, UUID fileId);
}
