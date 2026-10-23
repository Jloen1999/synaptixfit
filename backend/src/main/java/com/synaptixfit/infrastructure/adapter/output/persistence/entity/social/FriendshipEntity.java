package com.synaptixfit.infrastructure.adapter.output.persistence.entity.social;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code amistades}. */
@Entity
@Table(name = "amistades")
public class FriendshipEntity {

    @Id
    private UUID id;
    @Column(name = "solicitante_id", nullable = false)
    private UUID solicitanteId;
    @Column(name = "receptor_id", nullable = false)
    private UUID receptorId;
    @Column(nullable = false)
    private String estado;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "actualizado_en", nullable = false)
    private Instant actualizadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getSolicitanteId() { return solicitanteId; }
    public void setSolicitanteId(UUID solicitanteId) { this.solicitanteId = solicitanteId; }
    public UUID getReceptorId() { return receptorId; }
    public void setReceptorId(UUID receptorId) { this.receptorId = receptorId; }
    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant actualizadoEn) { this.actualizadoEn = actualizadoEn; }
}
