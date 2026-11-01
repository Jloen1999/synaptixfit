package com.synaptixfit.infrastructure.adapter.output.persistence.entity.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Tabla {@code dias_rutina}. */
@Entity
@Table(name = "dias_rutina")
public class RoutineDayEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "semana_id")
    private UUID semanaId;
    @Column(name = "numero_dia")
    private int numeroDia;
    @Column(name = "nombre")
    private String nombre;
    @Column(name = "estado")
    private String estado;
    @Column(name = "creado_en")
    private Instant creadoEn;
    /** Día en que se completó o se saltó (null si sigue por hacer). */
    @Column(name = "cerrado_en")
    private LocalDate cerradoEn;


    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getSemanaId() { return semanaId; }
    public void setSemanaId(UUID v) { this.semanaId = v; }
    public int getNumeroDia() { return numeroDia; }
    public void setNumeroDia(int v) { this.numeroDia = v; }
    public String getNombre() { return nombre; }
    public void setNombre(String v) { this.nombre = v; }
    public String getEstado() { return estado; }
    public void setEstado(String v) { this.estado = v; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant v) { this.creadoEn = v; }
    public LocalDate getCerradoEn() { return cerradoEn; }
    public void setCerradoEn(LocalDate v) { this.cerradoEn = v; }
}
