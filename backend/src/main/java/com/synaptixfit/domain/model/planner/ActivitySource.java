package com.synaptixfit.domain.model.planner;

/**
 * Origen de una actividad hecha (ADR 0037): apuntada a mano o grabada con el GPS de la app. Decide hasta cuántos días
 * atrás se acepta: una carrera grabada sin conexión puede subirse más tarde desde la cola de envíos del móvil.
 */
public enum ActivitySource {
    MANUAL(7),
    GPS(30);

    private final int maxDaysBack;

    ActivitySource(int maxDaysBack) {
        this.maxDaysBack = maxDaysBack;
    }

    public int maxDaysBack() {
        return maxDaysBack;
    }
}
