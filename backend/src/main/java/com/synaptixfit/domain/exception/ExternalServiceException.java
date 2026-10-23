package com.synaptixfit.domain.exception;

/** Categoría de error: Un servicio externo (IA, almacenamiento…) no está disponible. */
public abstract class ExternalServiceException extends DomainException {

    protected ExternalServiceException(String code, String message) {
        super(code, message);
    }
}
