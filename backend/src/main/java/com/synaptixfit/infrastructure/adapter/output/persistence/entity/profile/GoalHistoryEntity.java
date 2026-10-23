package com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Tabla {@code historial_objetivos}. */
@Entity
@Table(name = "historial_objetivos")
public class GoalHistoryEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID usuarioId;
    @Column(name = "objetivo", nullable = false)
    private String objetivo;
    @Column(name = "objetivo_anterior")
    private String objetivoAnterior;
    @Column(name = "fecha_inicio", nullable = false)
    private LocalDate fechaInicio;
    @Column(name = "fecha_fin")
    private LocalDate fechaFin;
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "rutina_ids")
    private List<UUID> rutinaIds;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public String getObjetivo() { return objetivo; }
    public void setObjetivo(String objetivo) { this.objetivo = objetivo; }
    public String getObjetivoAnterior() { return objetivoAnterior; }
    public void setObjetivoAnterior(String objetivoAnterior) { this.objetivoAnterior = objetivoAnterior; }
    public LocalDate getFechaInicio() { return fechaInicio; }
    public void setFechaInicio(LocalDate fechaInicio) { this.fechaInicio = fechaInicio; }
    public LocalDate getFechaFin() { return fechaFin; }
    public void setFechaFin(LocalDate fechaFin) { this.fechaFin = fechaFin; }
    public List<UUID> getRutinaIds() { return rutinaIds; }
    public void setRutinaIds(List<UUID> rutinaIds) { this.rutinaIds = rutinaIds; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
}
