package com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Tabla {@code planes_estudio}. */
@Entity
@Table(name = "planes_estudio")
public class StudyPlanEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;
    @Column(nullable = false)
    private String nombre;
    @Column(name = "semana_inicio", nullable = false)
    private LocalDate semanaInicio;
    @Column(name = "semana_fin", nullable = false)
    private LocalDate semanaFin;
    @Column(nullable = false)
    private String visibilidad;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "actualizado_en", nullable = false)
    private Instant actualizadoEn;
    @Column(name = "xp_planificacion_otorgado", nullable = false)
    private boolean xpPlanificacionOtorgado;
    @Column(name = "xp_planificacion_puntos", nullable = false)
    private int xpPlanificacionPuntos;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public LocalDate getSemanaInicio() { return semanaInicio; }
    public void setSemanaInicio(LocalDate semanaInicio) { this.semanaInicio = semanaInicio; }
    public LocalDate getSemanaFin() { return semanaFin; }
    public void setSemanaFin(LocalDate semanaFin) { this.semanaFin = semanaFin; }
    public String getVisibilidad() { return visibilidad; }
    public void setVisibilidad(String visibilidad) { this.visibilidad = visibilidad; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant actualizadoEn) { this.actualizadoEn = actualizadoEn; }
    public boolean isXpPlanificacionOtorgado() { return xpPlanificacionOtorgado; }
    public void setXpPlanificacionOtorgado(boolean v) { this.xpPlanificacionOtorgado = v; }
    public int getXpPlanificacionPuntos() { return xpPlanificacionPuntos; }
    public void setXpPlanificacionPuntos(int v) { this.xpPlanificacionPuntos = v; }
}
