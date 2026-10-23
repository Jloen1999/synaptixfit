package com.synaptixfit.domain.exception;

/** El almacenamiento de archivos no está disponible. */
public class StorageUnavailableException extends ExternalServiceException {

    public StorageUnavailableException(String message) {
        super("STORAGE_UNAVAILABLE", message);
    }
}
