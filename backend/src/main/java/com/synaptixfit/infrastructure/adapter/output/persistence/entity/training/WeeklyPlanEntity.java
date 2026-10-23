package com.synaptixfit.infrastructure.adapter.output.persistence.entity.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Tabla {@code plan_entrenamiento_semanal}. */
@Entity
@Table(name = "plan_entrenamiento_semanal")
public class WeeklyPlanEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "usuario_id")
    private UUID usuarioId;
    @Column(name = "semana_inicio")
    private LocalDate semanaInicio;
    @Column(name = "sesiones_planificadas")
    private int sesionesPlanificadas;
    @Column(name = "intensidad")
    private String intensidad;
    @Column(name = "duracion_min_por_sesion")
    private int duracionMinPorSesion;
    @Column(name = "estado")
    private String estado;
    @Column(name = "notas")
    private String notas;
    @Column(name = "creado_en")
    private Instant creadoEn;
    @Column(name = "actualizado_en")
    private Instant actualizadoEn;


    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID v) { this.usuarioId = v; }
    public LocalDate getSemanaInicio() { return semanaInicio; }
    public void setSemanaInicio(LocalDate v) { this.semanaInicio = v; }
    public int getSesionesPlanificadas() { return sesionesPlanificadas; }
    public void setSesionesPlanificadas(int v) { this.sesionesPlanificadas = v; }
    public String getIntensidad() { return intensidad; }
    public void setIntensidad(String v) { this.intensidad = v; }
    public int getDuracionMinPorSesion() { return duracionMinPorSesion; }
    public void setDuracionMinPorSesion(int v) { this.duracionMinPorSesion = v; }
    public String getEstado() { return estado; }
    public void setEstado(String v) { this.estado = v; }
    public String getNotas() { return notas; }
    public void setNotas(String v) { this.notas = v; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant v) { this.creadoEn = v; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant v) { this.actualizadoEn = v; }
}
