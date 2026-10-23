package com.synaptixfit.infrastructure.adapter.output.persistence.entity.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code semanas_rutina}. */
@Entity
@Table(name = "semanas_rutina")
public class RoutineWeekEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "rutina_id")
    private UUID rutinaId;
    @Column(name = "numero_semana")
    private int numeroSemana;
    @Column(name = "nombre")
    private String nombre;
    @Column(name = "estado")
    private String estado;
    @Column(name = "creado_en")
    private Instant creadoEn;
    @Column(name = "tipo_semana")
    private String tipoSemana;


    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getRutinaId() { return rutinaId; }
    public void setRutinaId(UUID v) { this.rutinaId = v; }
    public int getNumeroSemana() { return numeroSemana; }
    public void setNumeroSemana(int v) { this.numeroSemana = v; }
    public String getNombre() { return nombre; }
    public void setNombre(String v) { this.nombre = v; }
    public String getEstado() { return estado; }
    public void setEstado(String v) { this.estado = v; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant v) { this.creadoEn = v; }
    public String getTipoSemana() { return tipoSemana; }
    public void setTipoSemana(String v) { this.tipoSemana = v; }
}
