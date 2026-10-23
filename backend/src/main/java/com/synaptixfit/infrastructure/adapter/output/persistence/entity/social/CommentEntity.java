package com.synaptixfit.infrastructure.adapter.output.persistence.entity.social;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code comentarios_feed}. */
@Entity
@Table(name = "comentarios_feed")
public class CommentEntity {

    @Id
    private UUID id;
    @Column(name = "actividad_id", nullable = false, updatable = false)
    private UUID actividadId;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID usuarioId;
    @Column(nullable = false)
    private String texto;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "editado_en")
    private Instant editadoEn;
    @Column(nullable = false)
    private boolean eliminado;
    private Boolean reportado;
    @Column(name = "reportado_por")
    private UUID reportadoPor;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getActividadId() { return actividadId; }
    public void setActividadId(UUID actividadId) { this.actividadId = actividadId; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public String getTexto() { return texto; }
    public void setTexto(String texto) { this.texto = texto; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getEditadoEn() { return editadoEn; }
    public void setEditadoEn(Instant editadoEn) { this.editadoEn = editadoEn; }
    public boolean isEliminado() { return eliminado; }
    public void setEliminado(boolean eliminado) { this.eliminado = eliminado; }
    public Boolean getReportado() { return reportado; }
    public void setReportado(Boolean reportado) { this.reportado = reportado; }
    public UUID getReportadoPor() { return reportadoPor; }
    public void setReportadoPor(UUID reportadoPor) { this.reportadoPor = reportadoPor; }
}
