package com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

/** Tabla {@code bibliografia_asignatura} (solo lectura). */
@Entity
@Table(name = "bibliografia_asignatura")
public class BibliographyEntity {

    @Id
    private UUID id;
    @Column(name = "asignatura_id", nullable = false)
    private UUID asignaturaId;
    @Column(name = "referencia", nullable = false)
    private String referencia;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getAsignaturaId() { return asignaturaId; }
    public void setAsignaturaId(UUID asignaturaId) { this.asignaturaId = asignaturaId; }
    public String getReferencia() { return referencia; }
    public void setReferencia(String referencia) { this.referencia = referencia; }
}
