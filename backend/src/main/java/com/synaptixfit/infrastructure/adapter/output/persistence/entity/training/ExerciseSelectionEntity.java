package com.synaptixfit.infrastructure.adapter.output.persistence.entity.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.List;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Tabla {@code seleccion_de_ejercicios} (ejercicio planificado). */
@Entity
@Table(name = "seleccion_de_ejercicios")
public class ExerciseSelectionEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "rutina_id")
    private UUID rutinaId;
    @Column(name = "ejercicio_id")
    private UUID ejercicioId;
    @Column(name = "series")
    private int series;
    @Column(name = "repeticiones")
    private int repeticiones;
    @Column(name = "segundos_descanso")
    private int segundosDescanso;
    @Column(name = "indice_orden")
    private int indiceOrden;
    @Column(name = "dia_id")
    private UUID diaId;
    @Column(name = "peso_kg")
    private Double pesoKg;
    @Column(name = "duracion_objetivo_segundos")
    private Integer duracionObjetivoSegundos;
    @Column(name = "distancia_metros")
    private Integer distanciaMetros;
    @Column(name = "tiempo_isometrico_segundos")
    private Integer tiempoIsometricoSegundos;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "pesos_kg")
    private List<Double> pesosKg;
    @Column(name = "duracion_real_segundos")
    private Integer duracionRealSegundos;


    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getRutinaId() { return rutinaId; }
    public void setRutinaId(UUID v) { this.rutinaId = v; }
    public UUID getEjercicioId() { return ejercicioId; }
    public void setEjercicioId(UUID v) { this.ejercicioId = v; }
    public int getSeries() { return series; }
    public void setSeries(int v) { this.series = v; }
    public int getRepeticiones() { return repeticiones; }
    public void setRepeticiones(int v) { this.repeticiones = v; }
    public int getSegundosDescanso() { return segundosDescanso; }
    public void setSegundosDescanso(int v) { this.segundosDescanso = v; }
    public int getIndiceOrden() { return indiceOrden; }
    public void setIndiceOrden(int v) { this.indiceOrden = v; }
    public UUID getDiaId() { return diaId; }
    public void setDiaId(UUID v) { this.diaId = v; }
    public Double getPesoKg() { return pesoKg; }
    public void setPesoKg(Double v) { this.pesoKg = v; }
    public Integer getDuracionObjetivoSegundos() { return duracionObjetivoSegundos; }
    public void setDuracionObjetivoSegundos(Integer v) { this.duracionObjetivoSegundos = v; }
    public Integer getDistanciaMetros() { return distanciaMetros; }
    public void setDistanciaMetros(Integer v) { this.distanciaMetros = v; }
    public Integer getTiempoIsometricoSegundos() { return tiempoIsometricoSegundos; }
    public void setTiempoIsometricoSegundos(Integer v) { this.tiempoIsometricoSegundos = v; }
    public List<Double> getPesosKg() { return pesosKg; }
    public void setPesosKg(List<Double> v) { this.pesosKg = v; }
    public Integer getDuracionRealSegundos() { return duracionRealSegundos; }
    public void setDuracionRealSegundos(Integer v) { this.duracionRealSegundos = v; }
}
