package com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code carreras} (solo lectura). */
@Entity
@Table(name = "carreras")
public class DegreeEntity {

    @Id
    private UUID id;
    @Column(name = "centro_id", nullable = false)
    private UUID centroId;
    @Column(name = "nombre", nullable = false)
    private String nombre;
    @Column(name = "total_creditos")
    private Integer totalCreditos;
    @Column(name = "total_horas")
    private Integer totalHoras;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getCentroId() { return centroId; }
    public void setCentroId(UUID centroId) { this.centroId = centroId; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public Integer getTotalCreditos() { return totalCreditos; }
    public void setTotalCreditos(Integer totalCreditos) { this.totalCreditos = totalCreditos; }
    public Integer getTotalHoras() { return totalHoras; }
    public void setTotalHoras(Integer totalHoras) { this.totalHoras = totalHoras; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
}
