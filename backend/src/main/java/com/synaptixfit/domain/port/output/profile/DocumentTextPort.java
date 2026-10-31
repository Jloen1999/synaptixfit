package com.synaptixfit.domain.port.output.profile;

/**
 * Texto de un documento (PDF con capa de texto). Lanza EnrollmentFileInvalidException si está dañado y
 * AiAttachmentNotSupportedException si no tiene texto (escaneado o imagen).
 */
public interface DocumentTextPort {

    String textOf(byte[] content, String mimeType);
}
