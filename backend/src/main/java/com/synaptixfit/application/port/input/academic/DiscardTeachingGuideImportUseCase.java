package com.synaptixfit.application.port.input.academic;

import java.util.UUID;

/** Descarta una importación; si no se llegó a aplicar, borra también el PDF subido. */
public interface DiscardTeachingGuideImportUseCase {

    void discard(UUID userId, UUID importId);
}
