package com.synaptixfit.domain.model.privacy;

/** Tipo de borrado de datos personales. */
public enum ErasureMode {
    /** Se borra el contenido del usuario pero se conserva la cuenta (progreso a cero). */
    CONTENT_WIPED,
    /** RGPD: se borran los datos personales y el contenido; la cuenta queda anónima y desactivada. */
    ANONYMIZED,
    /** Se elimina la cuenta y todos sus datos. */
    DELETED
}
