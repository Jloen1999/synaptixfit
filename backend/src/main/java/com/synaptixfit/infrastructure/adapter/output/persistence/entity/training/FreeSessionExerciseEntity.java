package com.synaptixfit.infrastructure.adapter.output.persistence.entity.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

/** Tabla {@code ejercicios_sesion_libre}: la lista de ejercicios de una sesión libre (ADR 0067). */
@Entity
@Table(name = "ejercicios_sesion_libre")
public class FreeSessionExerciseEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "sesion_id")
    private UUID sesionId;
    @Column(name = "ejercicio_id")
    private UUID ejercicioId;
    @Column(name = "orden")
    private int orden;
    @Column(name = "series")
    private int series;
    @Column(name = "repeticiones")
    private int repeticiones;
    @Column(name = "descanso_segundos")
    private int descansoSegundos;
    @Column(name = "peso_kg")
    private Double pesoKg;
    @Column(name = "duracion_objetivo_segundos")
    private Integer duracionObjetivoSegundos;
    @Column(name = "distancia_metros")
    private Integer distanciaMetros;
    @Column(name = "segundos_isometricos")
    private Integer segundosIsometricos;
    @Column(name = "rep_min")
    private Integer repMin;
    @Column(name = "rep_max")
    private Integer repMax;
    @Column(name = "reps_en_reserva")
    private Integer repsEnReserva;

    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getSesionId() { return sesionId; }
    public void setSesionId(UUID v) { this.sesionId = v; }
    public UUID getEjercicioId() { return ejercicioId; }
    public void setEjercicioId(UUID v) { this.ejercicioId = v; }
    public int getOrden() { return orden; }
    public void setOrden(int v) { this.orden = v; }
    public int getSeries() { return series; }
    public void setSeries(int v) { this.series = v; }
    public int getRepeticiones() { return repeticiones; }
    public void setRepeticiones(int v) { this.repeticiones = v; }
    public int getDescansoSegundos() { return descansoSegundos; }
    public void setDescansoSegundos(int v) { this.descansoSegundos = v; }
    public Double getPesoKg() { return pesoKg; }
    public void setPesoKg(Double v) { this.pesoKg = v; }
    public Integer getDuracionObjetivoSegundos() { return duracionObjetivoSegundos; }
    public void setDuracionObjetivoSegundos(Integer v) { this.duracionObjetivoSegundos = v; }
    public Integer getDistanciaMetros() { return distanciaMetros; }
    public void setDistanciaMetros(Integer v) { this.distanciaMetros = v; }
    public Integer getSegundosIsometricos() { return segundosIsometricos; }
    public void setSegundosIsometricos(Integer v) { this.segundosIsometricos = v; }
    public Integer getRepMin() { return repMin; }
    public void setRepMin(Integer v) { this.repMin = v; }
    public Integer getRepMax() { return repMax; }
    public void setRepMax(Integer v) { this.repMax = v; }
    public Integer getRepsEnReserva() { return repsEnReserva; }
    public void setRepsEnReserva(Integer v) { this.repsEnReserva = v; }
}
