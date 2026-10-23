package com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

/** Tabla {@code prerrequisitos_asignatura} (solo lectura). */
@Entity
@Table(name = "prerrequisitos_asignatura")
public class PrerequisiteEntity {

    @Id
    private UUID id;
    @Column(name = "asignatura_id", nullable = false)
    private UUID asignaturaId;
    @Column(name = "nombre_asignatura", nullable = false)
    private String nombreAsignatura;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getAsignaturaId() { return asignaturaId; }
    public void setAsignaturaId(UUID asignaturaId) { this.asignaturaId = asignaturaId; }
    public String getNombreAsignatura() { return nombreAsignatura; }
    public void setNombreAsignatura(String nombreAsignatura) { this.nombreAsignatura = nombreAsignatura; }
}
