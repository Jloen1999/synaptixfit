package com.synaptixfit.domain.model.training;

/**
 * Estado de avance de un día o una semana de rutina. Solo un día puede quedar {@link #SKIPPED}
 * (saltado a mano o al completar uno posterior); una semana nunca.
 */
public enum ProgressStatus {
    PENDING,
    IN_PROGRESS,
    COMPLETED,
    SKIPPED;

    /** Hecho o saltado: el día ya no se propone como próximo y cuenta para cerrar la semana. */
    public boolean isClosed() {
        return this == COMPLETED || this == SKIPPED;
    }
}
