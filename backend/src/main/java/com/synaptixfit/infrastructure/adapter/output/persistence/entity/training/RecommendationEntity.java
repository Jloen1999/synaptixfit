package com.synaptixfit.infrastructure.adapter.output.persistence.entity.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Tabla {@code recomendaciones_pendientes}. */
@Entity
@Table(name = "recomendaciones_pendientes")
public class RecommendationEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "usuario_id")
    private UUID usuarioId;
    @Column(name = "tipo")
    private String tipo;
    @Column(name = "titulo")
    private String titulo;
    @Column(name = "descripcion")
    private String descripcion;
    @Column(name = "ejercicio_id")
    private UUID ejercicioId;
    @Column(name = "rutina_id")
    private UUID rutinaId;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "datos")
    private Map<String, Object> datos;
    @Column(name = "aplicada")
    private boolean aplicada;
    @Column(name = "creado_en")
    private Instant creadoEn;


    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID v) { this.usuarioId = v; }
    public String getTipo() { return tipo; }
    public void setTipo(String v) { this.tipo = v; }
    public String getTitulo() { return titulo; }
    public void setTitulo(String v) { this.titulo = v; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String v) { this.descripcion = v; }
    public UUID getEjercicioId() { return ejercicioId; }
    public void setEjercicioId(UUID v) { this.ejercicioId = v; }
    public UUID getRutinaId() { return rutinaId; }
    public void setRutinaId(UUID v) { this.rutinaId = v; }
    public Map<String, Object> getDatos() { return datos; }
    public void setDatos(Map<String, Object> v) { this.datos = v; }
    public boolean isAplicada() { return aplicada; }
    public void setAplicada(boolean v) { this.aplicada = v; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant v) { this.creadoEn = v; }
}
