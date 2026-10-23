package com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code materiales_estudio}. */
@Entity
@Table(name = "materiales_estudio")
public class StudyMaterialEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID userId;
    @Column(name = "asignatura_id", nullable = false)
    private UUID subjectId;
    @Column(name = "tipo_origen", nullable = false)
    private String originType;
    @Column(name = "origen_id", nullable = false)
    private UUID originId;
    @Column(name = "titulo", nullable = false)
    private String title;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant createdAt;
    @Column(name = "estado_dominio", nullable = false)
    private String masteryState;
    @Column(name = "ultimo_repaso_en")
    private Instant lastReviewedAt;
    @Column(name = "siguiente_repaso_en")
    private Instant nextReviewAt;
    @Column(name = "intervalo_actual_dias")
    private Integer intervalDays;
    @Column(name = "facilidad")
    private Float easeFactor;
    @Column(name = "repasos_completados")
    private Integer completedReviews;
    @Column(name = "repasos_fallidos")
    private Integer failedReviews;
    @Column(name = "xp_practica_otorgado", nullable = false)
    private boolean practiceXpAwarded;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public UUID getSubjectId() { return subjectId; }
    public void setSubjectId(UUID subjectId) { this.subjectId = subjectId; }
    public String getOriginType() { return originType; }
    public void setOriginType(String originType) { this.originType = originType; }
    public UUID getOriginId() { return originId; }
    public void setOriginId(UUID originId) { this.originId = originId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public String getMasteryState() { return masteryState; }
    public void setMasteryState(String masteryState) { this.masteryState = masteryState; }
    public Instant getLastReviewedAt() { return lastReviewedAt; }
    public void setLastReviewedAt(Instant lastReviewedAt) { this.lastReviewedAt = lastReviewedAt; }
    public Instant getNextReviewAt() { return nextReviewAt; }
    public void setNextReviewAt(Instant nextReviewAt) { this.nextReviewAt = nextReviewAt; }
    public Integer getIntervalDays() { return intervalDays; }
    public void setIntervalDays(Integer intervalDays) { this.intervalDays = intervalDays; }
    public Float getEaseFactor() { return easeFactor; }
    public void setEaseFactor(Float easeFactor) { this.easeFactor = easeFactor; }
    public Integer getCompletedReviews() { return completedReviews; }
    public void setCompletedReviews(Integer completedReviews) { this.completedReviews = completedReviews; }
    public Integer getFailedReviews() { return failedReviews; }
    public void setFailedReviews(Integer failedReviews) { this.failedReviews = failedReviews; }
    public boolean isPracticeXpAwarded() { return practiceXpAwarded; }
    public void setPracticeXpAwarded(boolean practiceXpAwarded) { this.practiceXpAwarded = practiceXpAwarded; }
}
