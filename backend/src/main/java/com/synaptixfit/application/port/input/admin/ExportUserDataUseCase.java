package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.privacy.UserDataExport;
import java.util.UUID;

/** Exporta todos los datos de un usuario (RGPD). Auditado. */
public interface ExportUserDataUseCase {

    UserDataExport exportUserData(UUID adminId, UUID userId);
}
