package com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Tabla {@code carga_academica_semanal}. */
@Entity
@Table(name = "carga_academica_semanal")
public class WeeklyLoadEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;
    @Column(name = "semana_inicio", nullable = false)
    private LocalDate semanaInicio;
    @Column(name = "horas_estudio_planeadas", nullable = false)
    private int horasEstudioPlaneadas;
    @Column(name = "horas_estudio_reales", nullable = false)
    private int horasEstudioReales;
    @Column(name = "evaluaciones_semana", nullable = false)
    private int evaluacionesSemana;
    @Column(name = "entregas_semana", nullable = false)
    private int entregasSemana;
    @Column(name = "nivel_estres", nullable = false)
    private int nivelEstres;
    @Column(name = "horas_sueno_promedio", nullable = false)
    private double horasSuenoPromedio;
    private String notas;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "actualizado_en", nullable = false)
    private Instant actualizadoEn;
    @Column(name = "xp_estudio_otorgado", nullable = false)
    private boolean xpEstudioOtorgado;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public LocalDate getSemanaInicio() { return semanaInicio; }
    public void setSemanaInicio(LocalDate semanaInicio) { this.semanaInicio = semanaInicio; }
    public int getHorasEstudioPlaneadas() { return horasEstudioPlaneadas; }
    public void setHorasEstudioPlaneadas(int v) { this.horasEstudioPlaneadas = v; }
    public int getHorasEstudioReales() { return horasEstudioReales; }
    public void setHorasEstudioReales(int v) { this.horasEstudioReales = v; }
    public int getEvaluacionesSemana() { return evaluacionesSemana; }
    public void setEvaluacionesSemana(int v) { this.evaluacionesSemana = v; }
    public int getEntregasSemana() { return entregasSemana; }
    public void setEntregasSemana(int v) { this.entregasSemana = v; }
    public int getNivelEstres() { return nivelEstres; }
    public void setNivelEstres(int v) { this.nivelEstres = v; }
    public double getHorasSuenoPromedio() { return horasSuenoPromedio; }
    public void setHorasSuenoPromedio(double v) { this.horasSuenoPromedio = v; }
    public String getNotas() { return notas; }
    public void setNotas(String notas) { this.notas = notas; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant actualizadoEn) { this.actualizadoEn = actualizadoEn; }
    public boolean isXpEstudioOtorgado() { return xpEstudioOtorgado; }
    public void setXpEstudioOtorgado(boolean v) { this.xpEstudioOtorgado = v; }
}
