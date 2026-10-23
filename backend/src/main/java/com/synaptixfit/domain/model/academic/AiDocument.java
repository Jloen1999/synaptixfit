package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Documento generado por la IA y guardado («cargar o generar»). Hay como mucho uno por
 * usuario, fuente y tipo: regenerar sobrescribe el contenido.
 *
 * <p>{@code content} es Markdown (resumen) o JSON serializado (mapa mental, guía docente,
 * marca de práctica); la codificación la resuelve un puerto de salida.
 */
public record AiDocument(UUID id, UUID userId, UUID subjectId, AiDocumentSource source, String sourceId,
                         AiDocumentType type, String sourceTitle, String content, Instant createdAt,
                         Instant updatedAt) {

    public AiDocument {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(source, "source");
        sourceId = Guard.notBlank(sourceId, "sourceId");
        Objects.requireNonNull(type, "type");
        content = content == null ? "" : content;
        Objects.requireNonNull(createdAt, "createdAt");
        Objects.requireNonNull(updatedAt, "updatedAt");
    }

    public static AiDocument create(UUID userId, UUID subjectId, AiDocumentSource source, String sourceId,
                                    AiDocumentType type, String sourceTitle, String content, Instant now) {
        return new AiDocument(UUID.randomUUID(), userId, subjectId, source, sourceId, type, sourceTitle, content,
                now, now);
    }

    /** Nuevo contenido conservando la identidad del documento (regenerar o editar). */
    public AiDocument withContent(String newContent, String newSourceTitle, UUID newSubjectId, Instant now) {
        return new AiDocument(id, userId, newSubjectId, source, sourceId, type,
                newSourceTitle == null ? sourceTitle : newSourceTitle, newContent, createdAt, now);
    }
}
