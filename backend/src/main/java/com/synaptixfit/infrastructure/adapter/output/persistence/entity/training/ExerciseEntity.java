package com.synaptixfit.infrastructure.adapter.output.persistence.entity.training;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Tabla {@code ejercicios} con sus tablas de relación (partes del cuerpo, músculos y equipamiento). Solo se usa para escribir; las lecturas van por SQL. */
@Entity
@Table(name = "ejercicios")
public class ExerciseEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "nombre")
    private String nombre;
    @Column(name = "url_gif")
    private String urlGif;
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "instrucciones")
    private String[] instrucciones;
    @Column(name = "dificultad")
    private String dificultad;
    @Column(name = "descripcion")
    private String descripcion;
    @Column(name = "creado_en")
    private Instant creadoEn;
    @Column(name = "actualizado_en")
    private Instant actualizadoEn;
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "finalidad")
    private String[] finalidad;
    @Column(name = "url_preview")
    private String urlPreview;
    @Column(name = "modalidad_entrenamiento")
    private String modalidadEntrenamiento;
    @Column(name = "categoria")
    private String categoria;
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "tipo_medicion")
    private String[] tipoMedicion;
    @Column(name = "es_circuito")
    private boolean esCircuito;
    @Column(name = "activo")
    private Boolean activo;
    @Column(name = "valor_met")
    private double valorMet;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "ejercicio_parte_cuerpo", joinColumns = @JoinColumn(name = "ejercicio_id"))
    @Column(name = "parte_cuerpo_id")
    private Set<Integer> bodyPartIds = new HashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "ejercicio_musculo_objetivo", joinColumns = @JoinColumn(name = "ejercicio_id"))
    @Column(name = "musculo_id")
    private Set<Integer> targetMuscleIds = new HashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "ejercicio_musculo_secundario", joinColumns = @JoinColumn(name = "ejercicio_id"))
    @Column(name = "musculo_id")
    private Set<Integer> secondaryMuscleIds = new HashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "ejercicio_equipamiento", joinColumns = @JoinColumn(name = "ejercicio_id"))
    @Column(name = "equipamiento_id")
    private Set<Integer> equipmentIds = new HashSet<>();

    public Set<Integer> getBodyPartIds() { return bodyPartIds; }
    public Set<Integer> getTargetMuscleIds() { return targetMuscleIds; }
    public Set<Integer> getSecondaryMuscleIds() { return secondaryMuscleIds; }
    public Set<Integer> getEquipmentIds() { return equipmentIds; }


    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public String getNombre() { return nombre; }
    public void setNombre(String v) { this.nombre = v; }
    public String getUrlGif() { return urlGif; }
    public void setUrlGif(String v) { this.urlGif = v; }
    public String[] getInstrucciones() { return instrucciones; }
    public void setInstrucciones(String[] v) { this.instrucciones = v; }
    public String getDificultad() { return dificultad; }
    public void setDificultad(String v) { this.dificultad = v; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String v) { this.descripcion = v; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant v) { this.creadoEn = v; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant v) { this.actualizadoEn = v; }
    public String[] getFinalidad() { return finalidad; }
    public void setFinalidad(String[] v) { this.finalidad = v; }
    public String getUrlPreview() { return urlPreview; }
    public void setUrlPreview(String v) { this.urlPreview = v; }
    public String getCategoria() { return categoria; }
    public void setCategoria(String v) { this.categoria = v; }
    public String getModalidadEntrenamiento() { return modalidadEntrenamiento; }
    public void setModalidadEntrenamiento(String v) { this.modalidadEntrenamiento = v; }
    public String[] getTipoMedicion() { return tipoMedicion; }
    public void setTipoMedicion(String[] v) { this.tipoMedicion = v; }
    public boolean isEsCircuito() { return esCircuito; }
    public void setEsCircuito(boolean v) { this.esCircuito = v; }
    public Boolean getActivo() { return activo; }
    public void setActivo(Boolean v) { this.activo = v; }
    public double getValorMet() { return valorMet; }
    public void setValorMet(double v) { this.valorMet = v; }
}
