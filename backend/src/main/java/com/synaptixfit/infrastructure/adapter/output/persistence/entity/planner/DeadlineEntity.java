package com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code entregas_examenes}. */
@Entity
@Table(name = "entregas_examenes")
public class DeadlineEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;
    @Column(name = "asignatura_id")
    private UUID asignaturaId;
    @Column(nullable = false)
    private String titulo;
    @Column(nullable = false)
    private String tipo;
    @Column(name = "fecha_limite", nullable = false)
    private Instant fechaLimite;
    @Column(nullable = false)
    private String dificultad;
    @Column(name = "esta_completado", nullable = false)
    private boolean estaCompletado;
    @Column(name = "plan_estudio_id")
    private UUID planEstudioId;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "actualizado_en", nullable = false)
    private Instant actualizadoEn;
    @Column(name = "xp_entrega_otorgado", nullable = false)
    private boolean xpEntregaOtorgado;
    private String descripcion;
    @Column(name = "hora_inicio_str")
    private String horaInicioStr;
    @Column(name = "ics_uid")
    private String icsUid;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public UUID getAsignaturaId() { return asignaturaId; }
    public void setAsignaturaId(UUID asignaturaId) { this.asignaturaId = asignaturaId; }
    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }
    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }
    public Instant getFechaLimite() { return fechaLimite; }
    public void setFechaLimite(Instant fechaLimite) { this.fechaLimite = fechaLimite; }
    public String getDificultad() { return dificultad; }
    public void setDificultad(String dificultad) { this.dificultad = dificultad; }
    public boolean isEstaCompletado() { return estaCompletado; }
    public void setEstaCompletado(boolean estaCompletado) { this.estaCompletado = estaCompletado; }
    public UUID getPlanEstudioId() { return planEstudioId; }
    public void setPlanEstudioId(UUID planEstudioId) { this.planEstudioId = planEstudioId; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant actualizadoEn) { this.actualizadoEn = actualizadoEn; }
    public boolean isXpEntregaOtorgado() { return xpEntregaOtorgado; }
    public void setXpEntregaOtorgado(boolean xpEntregaOtorgado) { this.xpEntregaOtorgado = xpEntregaOtorgado; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
    public String getHoraInicioStr() { return horaInicioStr; }
    public void setHoraInicioStr(String horaInicioStr) { this.horaInicioStr = horaInicioStr; }
    public String getIcsUid() { return icsUid; }
    public void setIcsUid(String icsUid) { this.icsUid = icsUid; }
}
