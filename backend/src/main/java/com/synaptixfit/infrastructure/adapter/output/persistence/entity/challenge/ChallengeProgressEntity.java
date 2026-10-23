package com.synaptixfit.infrastructure.adapter.output.persistence.entity.challenge;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code progreso_de_reto}. */
@Entity
@Table(name = "progreso_de_reto")
public class ChallengeProgressEntity {

    @Id
    private UUID id;
    @Column(name = "reto_id", nullable = false)
    private UUID retoId;
    @Column(name = "hito_id")
    private UUID hitoId;
    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;
    @Column(name = "cantidad_completada", nullable = false)
    private double cantidadCompletada;
    @Column(name = "registrado_en", nullable = false)
    private Instant registradoEn;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getRetoId() { return retoId; }
    public void setRetoId(UUID retoId) { this.retoId = retoId; }
    public UUID getHitoId() { return hitoId; }
    public void setHitoId(UUID hitoId) { this.hitoId = hitoId; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public double getCantidadCompletada() { return cantidadCompletada; }
    public void setCantidadCompletada(double cantidadCompletada) { this.cantidadCompletada = cantidadCompletada; }
    public Instant getRegistradoEn() { return registradoEn; }
    public void setRegistradoEn(Instant registradoEn) { this.registradoEn = registradoEn; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
}
