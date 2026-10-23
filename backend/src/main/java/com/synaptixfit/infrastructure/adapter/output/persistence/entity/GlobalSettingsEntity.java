package com.synaptixfit.infrastructure.adapter.output.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code configuracion_global} (una sola fila, id = true). */
@Entity
@Table(name = "configuracion_global")
public class GlobalSettingsEntity {

    @Id
    private Boolean id;
    @Column(name = "lockdown_activo", nullable = false)
    private boolean lockdownActivo;
    @Column(name = "lockdown_iniciado_en")
    private Instant lockdownIniciadoEn;
    @Column(name = "lockdown_iniciado_por")
    private UUID lockdownIniciadoPor;
    @Column(name = "actualizado_en", nullable = false)
    private Instant actualizadoEn;

    public Boolean getId() { return id; }
    public void setId(Boolean id) { this.id = id; }
    public boolean isLockdownActivo() { return lockdownActivo; }
    public void setLockdownActivo(boolean lockdownActivo) { this.lockdownActivo = lockdownActivo; }
    public Instant getLockdownIniciadoEn() { return lockdownIniciadoEn; }
    public void setLockdownIniciadoEn(Instant lockdownIniciadoEn) { this.lockdownIniciadoEn = lockdownIniciadoEn; }
    public UUID getLockdownIniciadoPor() { return lockdownIniciadoPor; }
    public void setLockdownIniciadoPor(UUID lockdownIniciadoPor) { this.lockdownIniciadoPor = lockdownIniciadoPor; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant actualizadoEn) { this.actualizadoEn = actualizadoEn; }
}
