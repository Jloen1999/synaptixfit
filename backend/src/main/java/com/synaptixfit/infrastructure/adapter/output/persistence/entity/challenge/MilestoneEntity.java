package com.synaptixfit.infrastructure.adapter.output.persistence.entity.challenge;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Tabla {@code hitos_de_reto} (tareas de un reto). */
@Entity
@Table(name = "hitos_de_reto")
public class MilestoneEntity {

    @Id
    private UUID id;
    @Column(name = "reto_id", nullable = false)
    private UUID retoId;
    @Column(nullable = false)
    private String titulo;
    @Column(name = "porcentaje_peso", nullable = false)
    private double porcentajePeso;
    @Column(name = "indice_orden", nullable = false)
    private int indiceOrden;
    @Column(name = "progreso_actual", nullable = false)
    private double progresoActual;
    @Column(name = "esta_completado", nullable = false)
    private boolean estaCompletado;
    @Column(nullable = false)
    private String estado;
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "dependencias", columnDefinition = "uuid[]")
    private UUID[] dependencias;
    @Column(name = "tipo_condicion", nullable = false)
    private String tipoCondicion;
    @Column(name = "condicion_n", nullable = false)
    private int condicionN;
    @Column(name = "asignatura_id")
    private UUID asignaturaId;
    @Column(nullable = false)
    private String dificultad;
    @Column(name = "entidad_vinculada_id")
    private UUID entidadVinculadaId;
    @Column(name = "entidad_vinculada_tipo")
    private String entidadVinculadaTipo;
    @Column(name = "xp_otorgado", nullable = false)
    private int xpOtorgado;
    @Column(name = "apunte_id")
    private UUID apunteId;
    @Column(name = "archivo_id")
    private UUID archivoId;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getRetoId() { return retoId; }
    public void setRetoId(UUID retoId) { this.retoId = retoId; }
    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }
    public double getPorcentajePeso() { return porcentajePeso; }
    public void setPorcentajePeso(double porcentajePeso) { this.porcentajePeso = porcentajePeso; }
    public int getIndiceOrden() { return indiceOrden; }
    public void setIndiceOrden(int indiceOrden) { this.indiceOrden = indiceOrden; }
    public double getProgresoActual() { return progresoActual; }
    public void setProgresoActual(double progresoActual) { this.progresoActual = progresoActual; }
    public boolean isEstaCompletado() { return estaCompletado; }
    public void setEstaCompletado(boolean estaCompletado) { this.estaCompletado = estaCompletado; }
    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }
    public UUID[] getDependencias() { return dependencias; }
    public void setDependencias(UUID[] dependencias) { this.dependencias = dependencias; }
    public String getTipoCondicion() { return tipoCondicion; }
    public void setTipoCondicion(String tipoCondicion) { this.tipoCondicion = tipoCondicion; }
    public int getCondicionN() { return condicionN; }
    public void setCondicionN(int condicionN) { this.condicionN = condicionN; }
    public UUID getAsignaturaId() { return asignaturaId; }
    public void setAsignaturaId(UUID asignaturaId) { this.asignaturaId = asignaturaId; }
    public String getDificultad() { return dificultad; }
    public void setDificultad(String dificultad) { this.dificultad = dificultad; }
    public UUID getEntidadVinculadaId() { return entidadVinculadaId; }
    public void setEntidadVinculadaId(UUID entidadVinculadaId) { this.entidadVinculadaId = entidadVinculadaId; }
    public String getEntidadVinculadaTipo() { return entidadVinculadaTipo; }
    public void setEntidadVinculadaTipo(String entidadVinculadaTipo) { this.entidadVinculadaTipo = entidadVinculadaTipo; }
    public int getXpOtorgado() { return xpOtorgado; }
    public void setXpOtorgado(int xpOtorgado) { this.xpOtorgado = xpOtorgado; }
    public UUID getApunteId() { return apunteId; }
    public void setApunteId(UUID apunteId) { this.apunteId = apunteId; }
    public UUID getArchivoId() { return archivoId; }
    public void setArchivoId(UUID archivoId) { this.archivoId = archivoId; }
}
