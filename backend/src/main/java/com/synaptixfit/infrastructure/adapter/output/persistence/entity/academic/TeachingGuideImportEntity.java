package com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code importaciones_plan_docente}. */
@Entity
@Table(name = "importaciones_plan_docente")
public class TeachingGuideImportEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID userId;
    @Column(name = "asignatura_destino")
    private UUID targetSubjectId;
    @Column(name = "clave_objeto", nullable = false)
    private String objectKey;
    @Column(name = "nombre_archivo", nullable = false)
    private String fileName;
    @Column(name = "tipo_mime", nullable = false)
    private String mimeType;
    @Column(name = "tamano_bytes", nullable = false)
    private long sizeBytes;
    @Column(name = "estado", nullable = false)
    private String status;
    @Column(name = "resultado")
    private String result;
    @Column(name = "codigo_error")
    private String errorCode;
    @Column(name = "asignatura_aplicada")
    private UUID appliedSubjectId;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant createdAt;
    @Column(name = "actualizado_en", nullable = false)
    private Instant updatedAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public UUID getTargetSubjectId() { return targetSubjectId; }
    public void setTargetSubjectId(UUID targetSubjectId) { this.targetSubjectId = targetSubjectId; }
    public String getObjectKey() { return objectKey; }
    public void setObjectKey(String objectKey) { this.objectKey = objectKey; }
    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }
    public String getMimeType() { return mimeType; }
    public void setMimeType(String mimeType) { this.mimeType = mimeType; }
    public long getSizeBytes() { return sizeBytes; }
    public void setSizeBytes(long sizeBytes) { this.sizeBytes = sizeBytes; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getResult() { return result; }
    public void setResult(String result) { this.result = result; }
    public String getErrorCode() { return errorCode; }
    public void setErrorCode(String errorCode) { this.errorCode = errorCode; }
    public UUID getAppliedSubjectId() { return appliedSubjectId; }
    public void setAppliedSubjectId(UUID appliedSubjectId) { this.appliedSubjectId = appliedSubjectId; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
