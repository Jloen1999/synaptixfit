package com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code centros} (solo lectura). */
@Entity
@Table(name = "centros")
public class CenterEntity {

    @Id
    private UUID id;
    @Column(name = "universidad_id", nullable = false)
    private UUID universidadId;
    @Column(name = "nombre", nullable = false)
    private String nombre;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUniversidadId() { return universidadId; }
    public void setUniversidadId(UUID universidadId) { this.universidadId = universidadId; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
}
