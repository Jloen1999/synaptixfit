package com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Tabla {@code perfil_academico_usuario}. */
@Entity
@Table(name = "perfil_academico_usuario")
public class AcademicProfileEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID usuarioId;
    @Column(name = "universidad")
    private String universidad;
    @Column(name = "carrera")
    private String carrera;
    @Column(name = "semestre_actual", nullable = false)
    private int semestreActual;
    @Column(name = "modalidad", nullable = false)
    private String modalidad;
    @Column(name = "creditos_semestre_actual", nullable = false)
    private int creditosSemestreActual;
    @Column(name = "horas_objetivo_estudio_semana", nullable = false)
    private int horasObjetivoEstudioSemana;
    @Column(name = "promedio_objetivo")
    private Double promedioObjetivo;
    @Column(name = "fecha_inicio_clases")
    private LocalDate fechaInicioClases;
    @Column(name = "fecha_fin_clases")
    private LocalDate fechaFinClases;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "actualizado_en", nullable = false)
    private Instant actualizadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public String getUniversidad() { return universidad; }
    public void setUniversidad(String universidad) { this.universidad = universidad; }
    public String getCarrera() { return carrera; }
    public void setCarrera(String carrera) { this.carrera = carrera; }
    public int getSemestreActual() { return semestreActual; }
    public void setSemestreActual(int semestreActual) { this.semestreActual = semestreActual; }
    public String getModalidad() { return modalidad; }
    public void setModalidad(String modalidad) { this.modalidad = modalidad; }
    public int getCreditosSemestreActual() { return creditosSemestreActual; }
    public void setCreditosSemestreActual(int creditosSemestreActual) { this.creditosSemestreActual = creditosSemestreActual; }
    public int getHorasObjetivoEstudioSemana() { return horasObjetivoEstudioSemana; }
    public void setHorasObjetivoEstudioSemana(int horasObjetivoEstudioSemana) { this.horasObjetivoEstudioSemana = horasObjetivoEstudioSemana; }
    public Double getPromedioObjetivo() { return promedioObjetivo; }
    public void setPromedioObjetivo(Double promedioObjetivo) { this.promedioObjetivo = promedioObjetivo; }
    public LocalDate getFechaInicioClases() { return fechaInicioClases; }
    public void setFechaInicioClases(LocalDate fechaInicioClases) { this.fechaInicioClases = fechaInicioClases; }
    public LocalDate getFechaFinClases() { return fechaFinClases; }
    public void setFechaFinClases(LocalDate fechaFinClases) { this.fechaFinClases = fechaFinClases; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant actualizadoEn) { this.actualizadoEn = actualizadoEn; }
}
