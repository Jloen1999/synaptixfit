package com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

/** Tabla {@code profesores_asignatura} (solo lectura). */
@Entity
@Table(name = "profesores_asignatura")
public class ProfessorEntity {

    @Id
    private UUID id;
    @Column(name = "asignatura_id", nullable = false)
    private UUID asignaturaId;
    @Column(name = "nombre_completo", nullable = false)
    private String nombreCompleto;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getAsignaturaId() { return asignaturaId; }
    public void setAsignaturaId(UUID asignaturaId) { this.asignaturaId = asignaturaId; }
    public String getNombreCompleto() { return nombreCompleto; }
    public void setNombreCompleto(String nombreCompleto) { this.nombreCompleto = nombreCompleto; }
}
