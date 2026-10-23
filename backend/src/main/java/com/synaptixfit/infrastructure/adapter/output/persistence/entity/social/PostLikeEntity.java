package com.synaptixfit.infrastructure.adapter.output.persistence.entity.social;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code interacciones_sociales} (solo «me gusta»). */
@Entity
@Table(name = "interacciones_sociales")
public class PostLikeEntity {

    public static final String LIKE = "like";

    @Id
    private UUID id;
    @Column(name = "actividad_id", nullable = false)
    private UUID actividadId;
    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;
    @Column(name = "tipo_interaccion", nullable = false)
    private String tipoInteraccion = LIKE;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getActividadId() { return actividadId; }
    public void setActividadId(UUID actividadId) { this.actividadId = actividadId; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public String getTipoInteraccion() { return tipoInteraccion; }
    public void setTipoInteraccion(String tipoInteraccion) { this.tipoInteraccion = tipoInteraccion; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
}
