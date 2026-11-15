package com.synaptixfit.infrastructure.adapter.output.persistence.entity.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Tabla {@code duraciones_ejercicio_rutina} (V1070, ADR 0048): duración real de un ejercicio planificado en una
 * sesión terminada. Se guardan como mucho tres por ejercicio ({@code PlannedExercise.RECENT_DURATIONS}).
 */
@Entity
@Table(name = "duraciones_ejercicio_rutina")
public class ExerciseDurationEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "ejercicio_seleccionado_id")
    private UUID seleccionId;
    @Column(name = "segundos")
    private int segundos;
    @Column(name = "registrada_en")
    private Instant registradaEn;

    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getSeleccionId() { return seleccionId; }
    public void setSeleccionId(UUID v) { this.seleccionId = v; }
    public int getSegundos() { return segundos; }
    public void setSegundos(int v) { this.segundos = v; }
    public Instant getRegistradaEn() { return registradaEn; }
    public void setRegistradaEn(Instant v) { this.registradaEn = v; }
}
