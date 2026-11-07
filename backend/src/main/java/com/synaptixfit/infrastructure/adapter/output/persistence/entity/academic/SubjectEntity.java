package com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code asignaturas}. */
@Entity
@Table(name = "asignaturas")
public class SubjectEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID userId;
    @Column(name = "nombre", nullable = false)
    private String name;
    @Column(name = "codigo")
    private String code;
    @Column(name = "descripcion")
    private String description;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant createdAt;
    @Column(name = "dificultad_percibida", nullable = false)
    private int perceivedDifficulty;
    @Column(name = "creditos", nullable = false)
    private int credits;
    @Column(name = "prioridad", nullable = false)
    private String priority;
    @Column(name = "proxima_evaluacion")
    private Instant nextAssessmentAt;
    @Column(name = "docente")
    private String teacher;
    @Column(name = "aula")
    private String room;
    @Column(name = "archivado", nullable = false)
    private boolean archived;
    @Column(name = "catalogo_asignatura_id")
    private UUID catalogSubjectId;
    @Column(name = "ics_url")
    private String icsUrl;
    @Column(name = "ultima_sincronizacion")
    private Instant lastSyncedAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public int getPerceivedDifficulty() { return perceivedDifficulty; }
    public void setPerceivedDifficulty(int perceivedDifficulty) { this.perceivedDifficulty = perceivedDifficulty; }
    public int getCredits() { return credits; }
    public void setCredits(int credits) { this.credits = credits; }
    public String getPriority() { return priority; }
    public void setPriority(String priority) { this.priority = priority; }
    public Instant getNextAssessmentAt() { return nextAssessmentAt; }
    public void setNextAssessmentAt(Instant nextAssessmentAt) { this.nextAssessmentAt = nextAssessmentAt; }
    public String getRoom() { return room; }
    public void setRoom(String room) { this.room = room; }
    public String getTeacher() { return teacher; }
    public void setTeacher(String teacher) { this.teacher = teacher; }
    public boolean isArchived() { return archived; }
    public void setArchived(boolean archived) { this.archived = archived; }
    public UUID getCatalogSubjectId() { return catalogSubjectId; }
    public void setCatalogSubjectId(UUID catalogSubjectId) { this.catalogSubjectId = catalogSubjectId; }
    public String getIcsUrl() { return icsUrl; }
    public void setIcsUrl(String icsUrl) { this.icsUrl = icsUrl; }
    public Instant getLastSyncedAt() { return lastSyncedAt; }
    public void setLastSyncedAt(Instant lastSyncedAt) { this.lastSyncedAt = lastSyncedAt; }
}
