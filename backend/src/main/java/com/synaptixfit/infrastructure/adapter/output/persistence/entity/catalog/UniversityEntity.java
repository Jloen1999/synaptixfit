package com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code universidades} (solo lectura). */
@Entity
@Table(name = "universidades")
public class UniversityEntity {

    @Id
    private UUID id;
    @Column(name = "nombre", nullable = false)
    private String nombre;
    @Column(name = "tipo")
    private String tipo;
    @Column(name = "comunidad")
    private String comunidad;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }
    public String getComunidad() { return comunidad; }
    public void setComunidad(String comunidad) { this.comunidad = comunidad; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
}
