package com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Tabla {@code sesiones_focus}. */
@Entity
@Table(name = "sesiones_focus")
public class FocusSessionEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;
    @Column(name = "duracion_minutos", nullable = false)
    private int duracionMinutos;
    @Column(name = "ciclos_completados", nullable = false)
    private int ciclosCompletados;
    @Column(name = "tipo_fase", nullable = false)
    private String tipoFase;
    @Column(nullable = false)
    private boolean completada;
    @Column(nullable = false)
    private LocalDate fecha;
    @Column(name = "bloque_id")
    private UUID bloqueId;
    @Column(name = "asignatura_id")
    private UUID asignaturaId;
    @Column(name = "xp_otorgado", nullable = false)
    private int xpOtorgado;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public int getDuracionMinutos() { return duracionMinutos; }
    public void setDuracionMinutos(int v) { this.duracionMinutos = v; }
    public int getCiclosCompletados() { return ciclosCompletados; }
    public void setCiclosCompletados(int v) { this.ciclosCompletados = v; }
    public String getTipoFase() { return tipoFase; }
    public void setTipoFase(String tipoFase) { this.tipoFase = tipoFase; }
    public boolean isCompletada() { return completada; }
    public void setCompletada(boolean completada) { this.completada = completada; }
    public LocalDate getFecha() { return fecha; }
    public void setFecha(LocalDate fecha) { this.fecha = fecha; }
    public UUID getBloqueId() { return bloqueId; }
    public void setBloqueId(UUID bloqueId) { this.bloqueId = bloqueId; }
    public UUID getAsignaturaId() { return asignaturaId; }
    public void setAsignaturaId(UUID asignaturaId) { this.asignaturaId = asignaturaId; }
    public int getXpOtorgado() { return xpOtorgado; }
    public void setXpOtorgado(int xpOtorgado) { this.xpOtorgado = xpOtorgado; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
}
