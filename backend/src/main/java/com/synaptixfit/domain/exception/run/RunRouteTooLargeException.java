package com.synaptixfit.domain.exception.run;

import com.synaptixfit.domain.exception.InvalidInputException;

/** La ruta de la carrera supera el límite de puntos o de tamaño de la petición (ADR 0037). */
public class RunRouteTooLargeException extends InvalidInputException {

    public RunRouteTooLargeException() {
        super("RUN_ROUTE_TOO_LARGE", "A run route can have up to 20000 points and 2 MB");
    }
}
