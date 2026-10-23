package com.synaptixfit.infrastructure.adapter.output.persistence.entity.badge;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code usuario_insignias}. */
@Entity
@Table(name = "usuario_insignias")
public class UserBadgeEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;
    @Column(name = "insignia_id", nullable = false)
    private UUID insigniaId;
    @Column(name = "obtenida_en", nullable = false, updatable = false)
    private Instant obtenidaEn;
    @Column(nullable = false)
    private boolean notificada;
    @Column(nullable = false)
    private boolean visible;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public UUID getInsigniaId() { return insigniaId; }
    public void setInsigniaId(UUID insigniaId) { this.insigniaId = insigniaId; }
    public Instant getObtenidaEn() { return obtenidaEn; }
    public void setObtenidaEn(Instant obtenidaEn) { this.obtenidaEn = obtenidaEn; }
    public boolean isNotificada() { return notificada; }
    public void setNotificada(boolean notificada) { this.notificada = notificada; }
    public boolean isVisible() { return visible; }
    public void setVisible(boolean visible) { this.visible = visible; }
}
