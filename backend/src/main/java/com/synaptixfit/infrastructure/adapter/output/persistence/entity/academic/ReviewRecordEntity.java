package com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code registros_repaso_srs}. */
@Entity
@Table(name = "registros_repaso_srs")
public class ReviewRecordEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "material_estudio_id", nullable = false, updatable = false)
    private UUID studyMaterialId;
    @Column(name = "fecha_repaso", nullable = false)
    private Instant reviewedAt;
    @Column(name = "q_real", nullable = false)
    private Short realQuality;
    @Column(name = "q_ajustado", nullable = false)
    private BigDecimal adjustedQuality;
    @Column(name = "coeficiente_fatiga", nullable = false)
    private BigDecimal fatigueCoefficient;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant createdAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getStudyMaterialId() { return studyMaterialId; }
    public void setStudyMaterialId(UUID studyMaterialId) { this.studyMaterialId = studyMaterialId; }
    public Instant getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(Instant reviewedAt) { this.reviewedAt = reviewedAt; }
    public Short getRealQuality() { return realQuality; }
    public void setRealQuality(Short realQuality) { this.realQuality = realQuality; }
    public BigDecimal getAdjustedQuality() { return adjustedQuality; }
    public void setAdjustedQuality(BigDecimal adjustedQuality) { this.adjustedQuality = adjustedQuality; }
    public BigDecimal getFatigueCoefficient() { return fatigueCoefficient; }
    public void setFatigueCoefficient(BigDecimal fatigueCoefficient) { this.fatigueCoefficient = fatigueCoefficient; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
