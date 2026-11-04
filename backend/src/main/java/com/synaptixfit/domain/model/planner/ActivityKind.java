package com.synaptixfit.domain.model.planner;

/** Clase de deporte apuntado a mano: decide si tiene sentido la distancia y qué icono pinta el cliente. */
public enum ActivityKind {
    RUN(true),
    WALK(true),
    BIKE(true),
    SWIM(true),
    MATCH(false),
    OTHER(false);

    private final boolean measuresDistance;

    ActivityKind(boolean measuresDistance) {
        this.measuresDistance = measuresDistance;
    }

    /** Correr, andar, bici y nadar se miden en distancia; un partido u otro deporte, no. */
    public boolean measuresDistance() {
        return measuresDistance;
    }
}
