package com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code horarios_academicos}. */
@Entity
@Table(name = "horarios_academicos")
public class CalendarBlockEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;
    @Column(name = "asignatura_id")
    private UUID asignaturaId;
    @Column(name = "hora_inicio", nullable = false)
    private Instant horaInicio;
    @Column(name = "hora_fin", nullable = false)
    private Instant horaFin;
    private String ubicacion;
    @Column(name = "tiene_conflicto", nullable = false)
    private boolean tieneConflicto;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "plan_estudio_id")
    private UUID planEstudioId;
    @Column(nullable = false)
    private String prioridad;
    @Column(name = "tipo_actividad", nullable = false)
    private String tipoActividad;
    @Column(name = "rutina_id")
    private UUID rutinaId;
    private String temas;
    @Column(nullable = false)
    private boolean completado;
    @Column(name = "asistencia_registrada_en")
    private Instant asistenciaRegistradaEn;
    @Column(nullable = false)
    private boolean ausente;
    @Column(name = "es_fijo", nullable = false)
    private boolean esFijo;
    @Column(name = "dia_semana")
    private Integer diaSemana;
    @Column(name = "xp_bloque_otorgado", nullable = false)
    private boolean xpBloqueOtorgado;
    @Column(name = "reto_id")
    private UUID retoId;
    @Column(name = "hito_id")
    private UUID hitoId;
    @Column(name = "dia_rutina_id")
    private UUID diaRutinaId;
    @Column(name = "semana_rutina_id")
    private UUID semanaRutinaId;
    @Column(name = "entrega_examen_id")
    private UUID entregaExamenId;
    @Column(name = "es_hito_inamovible", nullable = false)
    private boolean esHitoInamovible;
    @Column(name = "ics_uid")
    private String icsUid;
    @Column(name = "is_private", nullable = false)
    private boolean isPrivate;
    @Column(name = "tipo_clase")
    private String tipoClase;
    @Column(name = "met_value")
    private BigDecimal metValue;
    @Column(name = "calorias_quemadas")
    private BigDecimal caloriasQuemadas;
    @Column(name = "carga_cognitiva_generada")
    private BigDecimal cargaCognitivaGenerada;
    @Column(name = "material_estudio_id")
    private UUID materialEstudioId;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public UUID getAsignaturaId() { return asignaturaId; }
    public void setAsignaturaId(UUID asignaturaId) { this.asignaturaId = asignaturaId; }
    public Instant getHoraInicio() { return horaInicio; }
    public void setHoraInicio(Instant horaInicio) { this.horaInicio = horaInicio; }
    public Instant getHoraFin() { return horaFin; }
    public void setHoraFin(Instant horaFin) { this.horaFin = horaFin; }
    public String getUbicacion() { return ubicacion; }
    public void setUbicacion(String ubicacion) { this.ubicacion = ubicacion; }
    public boolean isTieneConflicto() { return tieneConflicto; }
    public void setTieneConflicto(boolean tieneConflicto) { this.tieneConflicto = tieneConflicto; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public UUID getPlanEstudioId() { return planEstudioId; }
    public void setPlanEstudioId(UUID planEstudioId) { this.planEstudioId = planEstudioId; }
    public String getPrioridad() { return prioridad; }
    public void setPrioridad(String prioridad) { this.prioridad = prioridad; }
    public String getTipoActividad() { return tipoActividad; }
    public void setTipoActividad(String tipoActividad) { this.tipoActividad = tipoActividad; }
    public UUID getRutinaId() { return rutinaId; }
    public void setRutinaId(UUID rutinaId) { this.rutinaId = rutinaId; }
    public String getTemas() { return temas; }
    public void setTemas(String temas) { this.temas = temas; }
    public boolean isCompletado() { return completado; }
    public void setCompletado(boolean completado) { this.completado = completado; }
    public Instant getAsistenciaRegistradaEn() { return asistenciaRegistradaEn; }
    public void setAsistenciaRegistradaEn(Instant v) { this.asistenciaRegistradaEn = v; }
    public boolean isAusente() { return ausente; }
    public void setAusente(boolean v) { this.ausente = v; }
    public boolean isEsFijo() { return esFijo; }
    public void setEsFijo(boolean esFijo) { this.esFijo = esFijo; }
    public Integer getDiaSemana() { return diaSemana; }
    public void setDiaSemana(Integer diaSemana) { this.diaSemana = diaSemana; }
    public boolean isXpBloqueOtorgado() { return xpBloqueOtorgado; }
    public void setXpBloqueOtorgado(boolean xpBloqueOtorgado) { this.xpBloqueOtorgado = xpBloqueOtorgado; }
    public UUID getRetoId() { return retoId; }
    public void setRetoId(UUID retoId) { this.retoId = retoId; }
    public UUID getHitoId() { return hitoId; }
    public void setHitoId(UUID hitoId) { this.hitoId = hitoId; }
    public UUID getDiaRutinaId() { return diaRutinaId; }
    public void setDiaRutinaId(UUID diaRutinaId) { this.diaRutinaId = diaRutinaId; }
    public UUID getSemanaRutinaId() { return semanaRutinaId; }
    public void setSemanaRutinaId(UUID semanaRutinaId) { this.semanaRutinaId = semanaRutinaId; }
    public UUID getEntregaExamenId() { return entregaExamenId; }
    public void setEntregaExamenId(UUID entregaExamenId) { this.entregaExamenId = entregaExamenId; }
    public boolean isEsHitoInamovible() { return esHitoInamovible; }
    public void setEsHitoInamovible(boolean esHitoInamovible) { this.esHitoInamovible = esHitoInamovible; }
    public String getIcsUid() { return icsUid; }
    public void setIcsUid(String icsUid) { this.icsUid = icsUid; }
    public boolean isPrivate() { return isPrivate; }
    public void setPrivate(boolean isPrivate) { this.isPrivate = isPrivate; }
    public String getTipoClase() { return tipoClase; }
    public void setTipoClase(String tipoClase) { this.tipoClase = tipoClase; }
    public BigDecimal getMetValue() { return metValue; }
    public void setMetValue(BigDecimal metValue) { this.metValue = metValue; }
    public BigDecimal getCaloriasQuemadas() { return caloriasQuemadas; }
    public void setCaloriasQuemadas(BigDecimal caloriasQuemadas) { this.caloriasQuemadas = caloriasQuemadas; }
    public BigDecimal getCargaCognitivaGenerada() { return cargaCognitivaGenerada; }
    public void setCargaCognitivaGenerada(BigDecimal v) { this.cargaCognitivaGenerada = v; }
    public UUID getMaterialEstudioId() { return materialEstudioId; }
    public void setMaterialEstudioId(UUID materialEstudioId) { this.materialEstudioId = materialEstudioId; }
}
