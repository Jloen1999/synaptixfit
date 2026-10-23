package com.synaptixfit.infrastructure.adapter.output.persistence.entity.social;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code actividades_sociales}. */
@Entity
@Table(name = "actividades_sociales")
public class PostEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID usuarioId;
    @Column(nullable = false)
    private String tipo;
    @Column(nullable = false)
    private String descripcion;
    @Column(name = "url_imagen")
    private String urlImagen;
    private String metadata;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "editado_en")
    private Instant editadoEn;
    private Boolean reportado;
    @Column(name = "reportado_por")
    private UUID reportadoPor;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
    public String getUrlImagen() { return urlImagen; }
    public void setUrlImagen(String urlImagen) { this.urlImagen = urlImagen; }
    public String getMetadata() { return metadata; }
    public void setMetadata(String metadata) { this.metadata = metadata; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getEditadoEn() { return editadoEn; }
    public void setEditadoEn(Instant editadoEn) { this.editadoEn = editadoEn; }
    public Boolean getReportado() { return reportado; }
    public void setReportado(Boolean reportado) { this.reportado = reportado; }
    public UUID getReportadoPor() { return reportadoPor; }
    public void setReportadoPor(UUID reportadoPor) { this.reportadoPor = reportadoPor; }
}
