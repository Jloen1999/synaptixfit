package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.privacy.ErasureReport;
import java.util.UUID;

/** Anonimiza otra cuenta (RGPD): datos personales y contenido fuera, sesiones revocadas. Idempotente. */
public interface AnonymizeUserUseCase {

    ErasureReport anonymizeUser(UUID adminId, UUID userId);
}
