package com.synaptixfit.application.port.input.privacy;

import com.synaptixfit.domain.model.privacy.UserDataExport;
import java.util.UUID;

/** Copia de todos los datos del usuario autenticado (RGPD, portabilidad). */
public interface ExportMyDataUseCase {

    UserDataExport exportMyData(UUID userId);
}
