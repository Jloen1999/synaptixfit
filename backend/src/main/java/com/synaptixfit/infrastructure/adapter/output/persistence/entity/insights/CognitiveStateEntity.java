package com.synaptixfit.infrastructure.adapter.output.persistence.entity.insights;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code estado_cognitivo_usuario} (1:1 con el usuario). */
@Entity
@Table(name = "estado_cognitivo_usuario")
public class CognitiveStateEntity {

    @Id
    @Column(name = "usuario_id")
    private UUID usuarioId;
    @Column(name = "carga_cognitiva_actual", nullable = false, precision = 6, scale = 4)
    private BigDecimal cargaCognitivaActual;
    @Column(name = "capacidad_atencion_actual", nullable = false, precision = 4, scale = 3)
    private BigDecimal capacidadAtencionActual;
    @Column(name = "duracion_ultimo_bloque_min", nullable = false)
    private int duracionUltimoBloqueMin;
    @Column(name = "fecha_ultimo_descanso")
    private Instant fechaUltimoDescanso;
    @Column(name = "rmr_base", precision = 6, scale = 2)
    private BigDecimal rmrBase;
    @Column(name = "creado_en", nullable = false)
    private Instant creadoEn;
    @Column(name = "actualizado_en", nullable = false)
    private Instant actualizadoEn;

    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public BigDecimal getCargaCognitivaActual() { return cargaCognitivaActual; }
    public void setCargaCognitivaActual(BigDecimal v) { this.cargaCognitivaActual = v; }
    public BigDecimal getCapacidadAtencionActual() { return capacidadAtencionActual; }
    public void setCapacidadAtencionActual(BigDecimal v) { this.capacidadAtencionActual = v; }
    public int getDuracionUltimoBloqueMin() { return duracionUltimoBloqueMin; }
    public void setDuracionUltimoBloqueMin(int v) { this.duracionUltimoBloqueMin = v; }
    public Instant getFechaUltimoDescanso() { return fechaUltimoDescanso; }
    public void setFechaUltimoDescanso(Instant v) { this.fechaUltimoDescanso = v; }
    public BigDecimal getRmrBase() { return rmrBase; }
    public void setRmrBase(BigDecimal rmrBase) { this.rmrBase = rmrBase; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant actualizadoEn) { this.actualizadoEn = actualizadoEn; }
}
