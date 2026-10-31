package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.profile.SetupChecklist;
import java.util.UUID;

/** Configuración pendiente del usuario para el aviso discreto de Inicio. */
public interface GetSetupChecklistUseCase {

    SetupChecklist getSetupChecklist(UUID userId);
}
