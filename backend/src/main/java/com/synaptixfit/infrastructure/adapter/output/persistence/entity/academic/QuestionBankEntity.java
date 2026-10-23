package com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code bancos_preguntas}. */
@Entity
@Table(name = "bancos_preguntas")
public class QuestionBankEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "material_id", nullable = false, updatable = false)
    private UUID materialId;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID userId;
    @Column(name = "xp_otorgado", nullable = false)
    private boolean xpAwarded;
    @Column(name = "generado_en", nullable = false)
    private Instant generatedAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getMaterialId() { return materialId; }
    public void setMaterialId(UUID materialId) { this.materialId = materialId; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public boolean isXpAwarded() { return xpAwarded; }
    public void setXpAwarded(boolean xpAwarded) { this.xpAwarded = xpAwarded; }
    public Instant getGeneratedAt() { return generatedAt; }
    public void setGeneratedAt(Instant generatedAt) { this.generatedAt = generatedAt; }
}
