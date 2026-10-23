package com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code apuntes}. */
@Entity
@Table(name = "apuntes")
public class NoteEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID userId;
    @Column(name = "asignatura_id")
    private UUID subjectId;
    @Column(name = "titulo", nullable = false)
    private String title;
    @Column(name = "contenido", nullable = false)
    private String content;
    @Column(name = "visibilidad", nullable = false)
    private String visibility;
    @Column(name = "es_nota_rapida", nullable = false)
    private boolean quickNote;
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
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public String getVisibility() { return visibility; }
    public void setVisibility(String visibility) { this.visibility = visibility; }
    public boolean isQuickNote() { return quickNote; }
    public void setQuickNote(boolean quickNote) { this.quickNote = quickNote; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
