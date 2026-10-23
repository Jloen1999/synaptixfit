package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.privacy.ErasureReport;
import java.util.UUID;

/** Borra el contenido de otro usuario conservando su cuenta (progreso a cero). Auditado. */
public interface WipeUserDataUseCase {

    ErasureReport wipeUserData(UUID adminId, UUID userId);
}
