package com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code usuario_carreras}. */
@Entity
@Table(name = "usuario_carreras")
public class UserDegreeEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID usuarioId;
    @Column(name = "carrera_id", nullable = false, updatable = false)
    private UUID carreraId;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public UUID getCarreraId() { return carreraId; }
    public void setCarreraId(UUID carreraId) { this.carreraId = carreraId; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
}
