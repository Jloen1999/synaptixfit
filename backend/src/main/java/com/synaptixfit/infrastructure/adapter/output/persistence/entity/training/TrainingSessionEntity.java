package com.synaptixfit.infrastructure.adapter.output.persistence.entity.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code sesiones_registradas}. */
@Entity
@Table(name = "sesiones_registradas")
public class TrainingSessionEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "usuario_id")
    private UUID usuarioId;
    @Column(name = "rutina_id")
    private UUID rutinaId;
    @Column(name = "duracion_minutos")
    private int duracionMinutos;
    @Column(name = "calorias_quemadas")
    private Double caloriasQuemadas;
    @Column(name = "rpe")
    private Integer rpe;
    @Column(name = "completada_en")
    private Instant completadaEn;
    @Column(name = "creado_en")
    private Instant creadoEn;
    @Column(name = "dia_id")
    private UUID diaId;
    @Column(name = "tipo")
    private String tipo;
    @Column(name = "xp_otorgado")
    private int xpOtorgado;
    @Column(name = "pausada_en")
    private Instant pausadaEn;
    @Column(name = "segundos_en_pausa")
    private int segundosEnPausa;

    public Instant getPausadaEn() { return pausadaEn; }
    public void setPausadaEn(Instant v) { this.pausadaEn = v; }
    public int getSegundosEnPausa() { return segundosEnPausa; }
    public void setSegundosEnPausa(int v) { this.segundosEnPausa = v; }


    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID v) { this.usuarioId = v; }
    public UUID getRutinaId() { return rutinaId; }
    public void setRutinaId(UUID v) { this.rutinaId = v; }
    public int getDuracionMinutos() { return duracionMinutos; }
    public void setDuracionMinutos(int v) { this.duracionMinutos = v; }
    public Double getCaloriasQuemadas() { return caloriasQuemadas; }
    public void setCaloriasQuemadas(Double v) { this.caloriasQuemadas = v; }
    public Integer getRpe() { return rpe; }
    public void setRpe(Integer v) { this.rpe = v; }
    public Instant getCompletadaEn() { return completadaEn; }
    public void setCompletadaEn(Instant v) { this.completadaEn = v; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant v) { this.creadoEn = v; }
    public UUID getDiaId() { return diaId; }
    public void setDiaId(UUID v) { this.diaId = v; }
    public String getTipo() { return tipo; }
    public void setTipo(String v) { this.tipo = v; }
    public int getXpOtorgado() { return xpOtorgado; }
    public void setXpOtorgado(int v) { this.xpOtorgado = v; }
}
