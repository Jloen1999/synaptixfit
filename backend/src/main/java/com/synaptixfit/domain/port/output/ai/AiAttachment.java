package com.synaptixfit.domain.port.output.ai;

/** Archivo adjunto a un prompt multimodal (PDF, imagen…). */
public record AiAttachment(String mimeType, byte[] data) {
}
