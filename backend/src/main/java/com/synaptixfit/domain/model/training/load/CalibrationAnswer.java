package com.synaptixfit.domain.model.training.load;

/** Respuesta a «¿Cuántas más podrías haber hecho?» tras la primera serie de un ejercicio nuevo (ADR 0054). */
public enum CalibrationAnswer {
    /** Ninguna: no podía más. */
    NONE,
    /** Una o dos. */
    ONE_TWO,
    /** Tres: lo justo para empezar. */
    THREE,
    /** Cuatro o más: el peso se queda corto. */
    FOUR_PLUS
}
