package com.synaptixfit.infrastructure.adapter.output.persistence.entity.insights;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Tabla {@code registros_carga_fisica}. {@code carga_diaria} es GENERATED (rpe x minutos). */
@Entity
@Table(name = "registros_carga_fisica")
public class PhysicalLoadEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;
    @Column(name = "fecha_registro", nullable = false)
    private LocalDate fechaRegistro;
    @Column(name = "rpe_sesion", nullable = false)
    private Short rpeSesion;
    @Column(name = "duracion_minutos", nullable = false)
    private Integer duracionMinutos;
    @Column(name = "carga_diaria", precision = 7, scale = 2, insertable = false, updatable = false)
    private BigDecimal cargaDiaria;
    @Column(name = "sesion_id")
    private UUID sesionId;
    @Column(name = "creado_en", nullable = false)
    private Instant creadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public LocalDate getFechaRegistro() { return fechaRegistro; }
    public void setFechaRegistro(LocalDate fechaRegistro) { this.fechaRegistro = fechaRegistro; }
    public Short getRpeSesion() { return rpeSesion; }
    public void setRpeSesion(Short rpeSesion) { this.rpeSesion = rpeSesion; }
    public Integer getDuracionMinutos() { return duracionMinutos; }
    public void setDuracionMinutos(Integer duracionMinutos) { this.duracionMinutos = duracionMinutos; }
    public BigDecimal getCargaDiaria() { return cargaDiaria; }
    public UUID getSesionId() { return sesionId; }
    public void setSesionId(UUID sesionId) { this.sesionId = sesionId; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
}
