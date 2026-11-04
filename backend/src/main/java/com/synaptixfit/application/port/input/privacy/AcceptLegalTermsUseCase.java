package com.synaptixfit.application.port.input.privacy;

import java.util.UUID;

/** Registra que la persona acepta la versión vigente de la política de privacidad y las condiciones. */
public interface AcceptLegalTermsUseCase {

    /** Lanza {@code LEGAL_VERSION_OUTDATED} si {@code version} no es la vigente (leyó un texto antiguo). */
    void acceptLegalTerms(UUID userId, String version);
}
