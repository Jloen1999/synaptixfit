package com.synaptixfit.domain.model.privacy;

/**
 * Quién responde de los datos y a qué correo escribir (RGPD, art. 13). Sale de la configuración del servidor
 * (ADR 0034): nunca se escribe en el código. Vacío: los textos dicen que está pendiente.
 */
public record LegalContact(String controllerName, String contactEmail) {

    public LegalContact {
        controllerName = blankToNull(controllerName);
        contactEmail = blankToNull(contactEmail);
    }

    /** Hay responsable y correo: los textos están completos. */
    public boolean configured() {
        return controllerName != null && contactEmail != null;
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
