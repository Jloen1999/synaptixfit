package com.synaptixfit.domain.model.planner;

/** Familia de un deporte del catálogo ({@link Sport}): decide qué se pregunta al apuntarlo. */
public enum SportCategory {
    /** Se mide en distancia: correr, andar, bici, natación. */
    ENDURANCE,
    /** Se juega contra alguien: admite «partido» o «entreno» y un resultado. */
    MATCH,
    /** Cualquier otro, con el nombre que le pone la persona. */
    OTHER
}
