package com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code asignaturas_catalogo} (solo lectura). */
@Entity
@Table(name = "asignaturas_catalogo")
public class CatalogSubjectEntity {

    @Id
    private UUID id;
    @Column(name = "carrera_id", nullable = false)
    private UUID carreraId;
    @Column(name = "nombre", nullable = false)
    private String nombre;
    @Column(name = "curso")
    private Integer curso;
    @Column(name = "semestre")
    private Integer semestre;
    @Column(name = "caracter")
    private String caracter;
    @Column(name = "creditos")
    private BigDecimal creditos;
    @Column(name = "horas")
    private Integer horas;
    @Column(name = "departamento")
    private String departamento;
    @Column(name = "idioma_imparticion")
    private String idiomaImparticion;
    @Column(name = "url_guia_docente")
    private String urlGuiaDocente;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getCarreraId() { return carreraId; }
    public void setCarreraId(UUID carreraId) { this.carreraId = carreraId; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public Integer getCurso() { return curso; }
    public void setCurso(Integer curso) { this.curso = curso; }
    public Integer getSemestre() { return semestre; }
    public void setSemestre(Integer semestre) { this.semestre = semestre; }
    public String getCaracter() { return caracter; }
    public void setCaracter(String caracter) { this.caracter = caracter; }
    public BigDecimal getCreditos() { return creditos; }
    public void setCreditos(BigDecimal creditos) { this.creditos = creditos; }
    public Integer getHoras() { return horas; }
    public void setHoras(Integer horas) { this.horas = horas; }
    public String getDepartamento() { return departamento; }
    public void setDepartamento(String departamento) { this.departamento = departamento; }
    public String getIdiomaImparticion() { return idiomaImparticion; }
    public void setIdiomaImparticion(String idiomaImparticion) { this.idiomaImparticion = idiomaImparticion; }
    public String getUrlGuiaDocente() { return urlGuiaDocente; }
    public void setUrlGuiaDocente(String urlGuiaDocente) { this.urlGuiaDocente = urlGuiaDocente; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
}
