package com.synaptixfit.domain.exception;

/**
 * Error de negocio con un {@code code} estable del catálogo {@code docs/03-api/errors.md}.
 *
 * <p>El dominio no conoce HTTP: la categoría (subclase abstracta) expresa la naturaleza del
 * fallo y la infraestructura decide el estado HTTP.
 */
public abstract class DomainException extends RuntimeException {

    private final String code;

    protected DomainException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String code() {
        return code;
    }
}
