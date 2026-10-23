package com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

/** Tabla {@code criterios_evaluacion} (solo lectura). */
@Entity
@Table(name = "criterios_evaluacion")
public class EvaluationCriteriaEntity {

    @Id
    private UUID id;
    @Column(name = "asignatura_id", nullable = false)
    private UUID asignaturaId;
    @Column(name = "examen_final_porcentaje")
    private Float examenFinalPorcentaje;
    @Column(name = "evaluacion_continua_porcentaje")
    private Float evaluacionContinuaPorcentaje;
    @Column(name = "practicas_laboratorio_porcentaje")
    private Float practicasLaboratorioPorcentaje;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getAsignaturaId() { return asignaturaId; }
    public void setAsignaturaId(UUID asignaturaId) { this.asignaturaId = asignaturaId; }
    public Float getExamenFinalPorcentaje() { return examenFinalPorcentaje; }
    public void setExamenFinalPorcentaje(Float examenFinalPorcentaje) { this.examenFinalPorcentaje = examenFinalPorcentaje; }
    public Float getEvaluacionContinuaPorcentaje() { return evaluacionContinuaPorcentaje; }
    public void setEvaluacionContinuaPorcentaje(Float evaluacionContinuaPorcentaje) { this.evaluacionContinuaPorcentaje = evaluacionContinuaPorcentaje; }
    public Float getPracticasLaboratorioPorcentaje() { return practicasLaboratorioPorcentaje; }
    public void setPracticasLaboratorioPorcentaje(Float practicasLaboratorioPorcentaje) { this.practicasLaboratorioPorcentaje = practicasLaboratorioPorcentaje; }
}
