package com.synaptixfit.domain.exception;

/** El proveedor de IA ha fallado o ha devuelto una respuesta inutilizable. */
public class AiUnavailableException extends ExternalServiceException {

    public AiUnavailableException(String message) {
        super("AI_UNAVAILABLE", message);
    }
}
