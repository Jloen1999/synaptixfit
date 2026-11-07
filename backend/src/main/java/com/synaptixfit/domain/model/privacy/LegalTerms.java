package com.synaptixfit.domain.model.privacy;

/**
 * Versión vigente de la política de privacidad y las condiciones (ADR 0034). Se acepta junta; al cambiar
 * {@link #CURRENT_VERSION} (la fecha del cambio), quien entre en la app debe volver a aceptarla.
 */
public final class LegalTerms {

    /**
     * Fecha de la versión vigente (ISO). Cambiarla obliga a aceptar de nuevo. 2026-11-07: la política suma la
     * ubicación exacta mientras se graba una carrera (ADR 0037).
     */
    public static final String CURRENT_VERSION = "2026-11-07";

    private LegalTerms() {
    }

    /** Hay que pedir la aceptación si nunca se aceptó o se aceptó una versión anterior. */
    public static boolean acceptanceRequired(String acceptedVersion) {
        return !CURRENT_VERSION.equals(acceptedVersion);
    }
}
