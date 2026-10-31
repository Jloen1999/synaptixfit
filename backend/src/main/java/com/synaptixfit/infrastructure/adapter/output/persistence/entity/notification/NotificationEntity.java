package com.synaptixfit.infrastructure.adapter.output.persistence.entity.notification;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Tabla {@code notificaciones}. */
@Entity
@Table(name = "notificaciones")
public class NotificationEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID usuarioId;
    @Column(nullable = false)
    private String titulo;
    private String descripcion;
    @Column(nullable = false)
    private String prioridad;
    @Column(nullable = false)
    private String tipo;
    @Column(name = "url_accion")
    private String urlAccion;
    @Column(name = "etiqueta_accion")
    private String etiquetaAccion;
    @Column(name = "clave_referencia")
    private String claveReferencia;
    @Column(name = "codigo_mensaje")
    private String codigoMensaje;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "parametros_mensaje")
    private Map<String, String> parametrosMensaje;
    @Column(name = "esta_leida", nullable = false)
    private boolean estaLeida;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "leida_en")
    private Instant leidaEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
    public String getPrioridad() { return prioridad; }
    public void setPrioridad(String prioridad) { this.prioridad = prioridad; }
    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }
    public String getUrlAccion() { return urlAccion; }
    public void setUrlAccion(String urlAccion) { this.urlAccion = urlAccion; }
    public String getEtiquetaAccion() { return etiquetaAccion; }
    public void setEtiquetaAccion(String etiquetaAccion) { this.etiquetaAccion = etiquetaAccion; }
    public String getClaveReferencia() { return claveReferencia; }
    public String getCodigoMensaje() { return codigoMensaje; }
    public void setCodigoMensaje(String codigoMensaje) { this.codigoMensaje = codigoMensaje; }
    public Map<String, String> getParametrosMensaje() { return parametrosMensaje; }
    public void setParametrosMensaje(Map<String, String> parametrosMensaje) { this.parametrosMensaje = parametrosMensaje; }
    public void setClaveReferencia(String claveReferencia) { this.claveReferencia = claveReferencia; }
    public boolean isEstaLeida() { return estaLeida; }
    public void setEstaLeida(boolean estaLeida) { this.estaLeida = estaLeida; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getLeidaEn() { return leidaEn; }
    public void setLeidaEn(Instant leidaEn) { this.leidaEn = leidaEn; }
}
