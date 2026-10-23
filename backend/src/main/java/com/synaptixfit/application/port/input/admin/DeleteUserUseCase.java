package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.privacy.ErasureReport;
import java.util.UUID;

/** Elimina otra cuenta y todos sus datos. Auditado. */
public interface DeleteUserUseCase {

    ErasureReport deleteUser(UUID adminId, UUID userId);
}
