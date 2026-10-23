package com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code archivos_asignatura}. */
@Entity
@Table(name = "archivos_asignatura")
public class SubjectFileEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID userId;
    @Column(name = "asignatura_id", nullable = false)
    private UUID subjectId;
    @Column(name = "nombre_archivo", nullable = false)
    private String fileName;
    @Column(name = "cloudflare_object_key", nullable = false)
    private String objectKey;
    @Column(name = "url_publica_o_firmada", nullable = false)
    private String storedUrl;
    @Column(name = "tamano_bytes", nullable = false)
    private long sizeBytes;
    @Column(name = "tipo_mime")
    private String mimeType;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant createdAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public UUID getSubjectId() { return subjectId; }
    public void setSubjectId(UUID subjectId) { this.subjectId = subjectId; }
    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }
    public String getObjectKey() { return objectKey; }
    public void setObjectKey(String objectKey) { this.objectKey = objectKey; }
    public String getStoredUrl() { return storedUrl; }
    public void setStoredUrl(String storedUrl) { this.storedUrl = storedUrl; }
    public long getSizeBytes() { return sizeBytes; }
    public void setSizeBytes(long sizeBytes) { this.sizeBytes = sizeBytes; }
    public String getMimeType() { return mimeType; }
    public void setMimeType(String mimeType) { this.mimeType = mimeType; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
