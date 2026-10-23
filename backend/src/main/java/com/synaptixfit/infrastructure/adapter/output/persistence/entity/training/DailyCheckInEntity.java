package com.synaptixfit.infrastructure.adapter.output.persistence.entity.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Tabla {@code estado_diario_usuario} (check-in diario). */
@Entity
@Table(name = "estado_diario_usuario")
public class DailyCheckInEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "usuario_id")
    private UUID usuarioId;
    @Column(name = "fecha")
    private LocalDate fecha;
    @Column(name = "calidad_sueno")
    private Integer calidadSueno;
    @Column(name = "nivel_estres")
    private Integer nivelEstres;
    @Column(name = "nivel_energia")
    private Integer nivelEnergia;
    @Column(name = "dolor_muscular")
    private Integer dolorMuscular;
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "zonas_dolor")
    private String[] zonasDolor;
    @Column(name = "listo_para_entrenar")
    private Boolean listoParaEntrenar;
    @Column(name = "notas")
    private String notas;
    @Column(name = "creado_en")
    private Instant creadoEn;


    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID v) { this.usuarioId = v; }
    public LocalDate getFecha() { return fecha; }
    public void setFecha(LocalDate v) { this.fecha = v; }
    public Integer getCalidadSueno() { return calidadSueno; }
    public void setCalidadSueno(Integer v) { this.calidadSueno = v; }
    public Integer getNivelEstres() { return nivelEstres; }
    public void setNivelEstres(Integer v) { this.nivelEstres = v; }
    public Integer getNivelEnergia() { return nivelEnergia; }
    public void setNivelEnergia(Integer v) { this.nivelEnergia = v; }
    public Integer getDolorMuscular() { return dolorMuscular; }
    public void setDolorMuscular(Integer v) { this.dolorMuscular = v; }
    public String[] getZonasDolor() { return zonasDolor; }
    public void setZonasDolor(String[] v) { this.zonasDolor = v; }
    public Boolean getListoParaEntrenar() { return listoParaEntrenar; }
    public void setListoParaEntrenar(Boolean v) { this.listoParaEntrenar = v; }
    public String getNotas() { return notas; }
    public void setNotas(String v) { this.notas = v; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant v) { this.creadoEn = v; }
}
