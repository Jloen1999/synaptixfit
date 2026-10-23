package com.synaptixfit.infrastructure.adapter.output.persistence.entity.badge;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code insignias} (catálogo, de solo lectura para la aplicación). */
@Entity
@Table(name = "insignias")
public class BadgeEntity {

    @Id
    private UUID id;
    @Column(nullable = false)
    private String nombre;
    @Column(nullable = false)
    private String descripcion;
    @Column(nullable = false)
    private String icono;
    @Column(nullable = false)
    private String categoria;
    @Column(name = "criterio_tipo", nullable = false)
    private String criterioTipo;
    @Column(name = "criterio_valor", nullable = false)
    private int criterioValor;
    @Column(nullable = false)
    private String rareza;
    @Column(nullable = false)
    private int orden;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    public UUID getId() { return id; }
    public String getNombre() { return nombre; }
    public String getDescripcion() { return descripcion; }
    public String getIcono() { return icono; }
    public String getCategoria() { return categoria; }
    public String getCriterioTipo() { return criterioTipo; }
    public int getCriterioValor() { return criterioValor; }
    public String getRareza() { return rareza; }
    public int getOrden() { return orden; }
    public Instant getCreadoEn() { return creadoEn; }
}
