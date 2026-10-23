package com.synaptixfit.infrastructure.adapter.output.persistence.entity.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Tabla {@code rutinas}. */
@Entity
@Table(name = "rutinas")
public class RoutineEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "usuario_id")
    private UUID usuarioId;
    @Column(name = "nombre")
    private String nombre;
    @Column(name = "descripcion")
    private String descripcion;
    @Column(name = "visibilidad")
    private String visibilidad;
    @Column(name = "cantidad_ejercicios")
    private int cantidadEjercicios;
    @Column(name = "creado_en")
    private Instant creadoEn;
    @Column(name = "actualizado_en")
    private Instant actualizadoEn;
    @Column(name = "eliminado_en")
    private Instant eliminadoEn;
    @Column(name = "duracion_semanas")
    private int duracionSemanas;
    @Column(name = "estado")
    private String estado;
    @Column(name = "objetivo")
    private String objetivo;
    @Column(name = "fecha_inicio")
    private LocalDate fechaInicio;
    @Column(name = "origen_id")
    private UUID origenId;
    @Column(name = "origen_propietario_id")
    private UUID origenPropietarioId;
    @Column(name = "origen_propietario_nombre")
    private String origenPropietarioNombre;


    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID v) { this.usuarioId = v; }
    public String getNombre() { return nombre; }
    public void setNombre(String v) { this.nombre = v; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String v) { this.descripcion = v; }
    public String getVisibilidad() { return visibilidad; }
    public void setVisibilidad(String v) { this.visibilidad = v; }
    public int getCantidadEjercicios() { return cantidadEjercicios; }
    public void setCantidadEjercicios(int v) { this.cantidadEjercicios = v; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant v) { this.creadoEn = v; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant v) { this.actualizadoEn = v; }
    public Instant getEliminadoEn() { return eliminadoEn; }
    public void setEliminadoEn(Instant v) { this.eliminadoEn = v; }
    public int getDuracionSemanas() { return duracionSemanas; }
    public void setDuracionSemanas(int v) { this.duracionSemanas = v; }
    public String getEstado() { return estado; }
    public void setEstado(String v) { this.estado = v; }
    public String getObjetivo() { return objetivo; }
    public void setObjetivo(String v) { this.objetivo = v; }
    public LocalDate getFechaInicio() { return fechaInicio; }
    public void setFechaInicio(LocalDate v) { this.fechaInicio = v; }
    public UUID getOrigenId() { return origenId; }
    public void setOrigenId(UUID v) { this.origenId = v; }
    public UUID getOrigenPropietarioId() { return origenPropietarioId; }
    public void setOrigenPropietarioId(UUID v) { this.origenPropietarioId = v; }
    public String getOrigenPropietarioNombre() { return origenPropietarioNombre; }
    public void setOrigenPropietarioNombre(String v) { this.origenPropietarioNombre = v; }
}
