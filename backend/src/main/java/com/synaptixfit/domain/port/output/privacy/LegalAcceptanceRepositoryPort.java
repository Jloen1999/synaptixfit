package com.synaptixfit.domain.port.output.privacy;

import com.synaptixfit.domain.model.privacy.LegalAcceptance;
import java.util.Optional;
import java.util.UUID;

/** Guarda y lee las aceptaciones de la política de privacidad y las condiciones (ADR 0034). */
public interface LegalAcceptanceRepositoryPort {

    /** La aceptación más reciente; vacía si nunca aceptó ninguna versión. */
    Optional<LegalAcceptance> latest(UUID userId);

    /** Guarda la aceptación; aceptar dos veces la misma versión no duplica la fila. */
    void save(LegalAcceptance acceptance);
}
