package com.synaptixfit.infrastructure.adapter.output.persistence.entity.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code series_sesion}. */
@Entity
@Table(name = "series_sesion")
public class SessionSetEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "sesion_id")
    private UUID sesionId;
    @Column(name = "seleccion_id")
    private UUID seleccionId;
    @Column(name = "numero_serie")
    private int numeroSerie;
    @Column(name = "repeticiones_realizadas")
    private Integer repeticionesRealizadas;
    @Column(name = "peso_kg")
    private Double pesoKg;
    @Column(name = "completada")
    private boolean completada;
    @Column(name = "creado_en")
    private Instant creadoEn;
    @Column(name = "failed_reps")
    private int failedReps;
    @Column(name = "duracion_segundos")
    private Integer duracionSegundos;
    @Column(name = "distancia_metros")
    private Integer distanciaMetros;
    @Column(name = "segundos_activos")
    private Integer segundosActivos;

    public Integer getSegundosActivos() { return segundosActivos; }
    public void setSegundosActivos(Integer v) { this.segundosActivos = v; }

    @Column(name = "ejercicio_id")
    private UUID ejercicioId;
    @Column(name = "calentamiento")
    private boolean calentamiento;
    @Column(name = "al_fallo")
    private boolean alFallo;

    public boolean isCalentamiento() { return calentamiento; }
    public void setCalentamiento(boolean v) { this.calentamiento = v; }
    public boolean isAlFallo() { return alFallo; }
    public void setAlFallo(boolean v) { this.alFallo = v; }


    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getSesionId() { return sesionId; }
    public void setSesionId(UUID v) { this.sesionId = v; }
    public UUID getSeleccionId() { return seleccionId; }
    public void setSeleccionId(UUID v) { this.seleccionId = v; }
    public int getNumeroSerie() { return numeroSerie; }
    public void setNumeroSerie(int v) { this.numeroSerie = v; }
    public Integer getRepeticionesRealizadas() { return repeticionesRealizadas; }
    public void setRepeticionesRealizadas(Integer v) { this.repeticionesRealizadas = v; }
    public Double getPesoKg() { return pesoKg; }
    public void setPesoKg(Double v) { this.pesoKg = v; }
    public boolean isCompletada() { return completada; }
    public void setCompletada(boolean v) { this.completada = v; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant v) { this.creadoEn = v; }
    public int getFailedReps() { return failedReps; }
    public void setFailedReps(int v) { this.failedReps = v; }
    public Integer getDuracionSegundos() { return duracionSegundos; }
    public void setDuracionSegundos(Integer v) { this.duracionSegundos = v; }
    public Integer getDistanciaMetros() { return distanciaMetros; }
    public void setDistanciaMetros(Integer v) { this.distanciaMetros = v; }
    public UUID getEjercicioId() { return ejercicioId; }
    public void setEjercicioId(UUID v) { this.ejercicioId = v; }
}
