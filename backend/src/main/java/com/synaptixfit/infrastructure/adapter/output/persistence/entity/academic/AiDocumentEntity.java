package com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code documentos_ia}. */
@Entity
@Table(name = "documentos_ia")
public class AiDocumentEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID userId;
    @Column(name = "asignatura_id")
    private UUID subjectId;
    @Column(name = "fuente_tipo", nullable = false)
    private String sourceType;
    @Column(name = "fuente_id", nullable = false)
    private String sourceId;
    @Column(name = "tipo", nullable = false)
    private String type;
    @Column(name = "fuente_titulo")
    private String sourceTitle;
    @Column(name = "contenido", nullable = false)
    private String content;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant createdAt;
    @Column(name = "actualizado_en", nullable = false)
    private Instant updatedAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public UUID getSubjectId() { return subjectId; }
    public void setSubjectId(UUID subjectId) { this.subjectId = subjectId; }
    public String getSourceType() { return sourceType; }
    public void setSourceType(String sourceType) { this.sourceType = sourceType; }
    public String getSourceId() { return sourceId; }
    public void setSourceId(String sourceId) { this.sourceId = sourceId; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getSourceTitle() { return sourceTitle; }
    public void setSourceTitle(String sourceTitle) { this.sourceTitle = sourceTitle; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
