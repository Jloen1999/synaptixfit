package com.synaptixfit.domain.exception;

/**
 * El proveedor de IA no puede leer este tipo de archivo (DeepSeek solo entiende texto: los PDF se
 * convierten a texto, pero las imágenes y los PDF escaneados sin texto no).
 */
public class AiAttachmentNotSupportedException extends BusinessRuleException {

    public AiAttachmentNotSupportedException(String mimeType) {
        super("AI_ATTACHMENT_UNSUPPORTED", "The AI provider cannot read attachments of type " + mimeType);
    }
}
