package com.synaptixfit.infrastructure.adapter.output.persistence.entity.insights;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code estado_regulacion_cruzada} (1:1 con el usuario). {@code acwr_actual} es GENERATED. */
@Entity
@Table(name = "estado_regulacion_cruzada")
public class CrossRegulationEntity {

    @Id
    @Column(name = "usuario_id")
    private UUID usuarioId;
    @Column(name = "carga_aguda_7d", precision = 8, scale = 2)
    private BigDecimal cargaAguda7d;
    @Column(name = "carga_cronica_28d", precision = 8, scale = 2)
    private BigDecimal cargaCronica28d;
    @Column(name = "acwr_actual", precision = 4, scale = 2, insertable = false, updatable = false)
    private BigDecimal acwrActual;
    @Column(name = "min_estudio_max_recomendado", nullable = false)
    private int minEstudioMaxRecomendado;
    @Column(name = "dias_proximo_examen")
    private Integer diasProximoExamen;
    @Column(name = "creado_en", nullable = false)
    private Instant creadoEn;
    @Column(name = "actualizado_en", nullable = false)
    private Instant actualizadoEn;

    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public BigDecimal getCargaAguda7d() { return cargaAguda7d; }
    public void setCargaAguda7d(BigDecimal cargaAguda7d) { this.cargaAguda7d = cargaAguda7d; }
    public BigDecimal getCargaCronica28d() { return cargaCronica28d; }
    public void setCargaCronica28d(BigDecimal cargaCronica28d) { this.cargaCronica28d = cargaCronica28d; }
    public BigDecimal getAcwrActual() { return acwrActual; }
    public int getMinEstudioMaxRecomendado() { return minEstudioMaxRecomendado; }
    public void setMinEstudioMaxRecomendado(int v) { this.minEstudioMaxRecomendado = v; }
    public Integer getDiasProximoExamen() { return diasProximoExamen; }
    public void setDiasProximoExamen(Integer diasProximoExamen) { this.diasProximoExamen = diasProximoExamen; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant actualizadoEn) { this.actualizadoEn = actualizadoEn; }
}
