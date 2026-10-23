package com.synaptixfit.domain.model.academic;

/** Autorización de subida: clave de objeto reservada y URL prefirmada para el PUT. */
public record FileUploadTicket(String objectKey, SignedUrl upload) {
}
