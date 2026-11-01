package com.synaptixfit.infrastructure.adapter.output.persistence.entity.challenge;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Tabla {@code retos}. */
@Entity
@Table(name = "retos")
public class ChallengeEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;
    @Column(nullable = false)
    private String titulo;
    @Column(nullable = false)
    private String tipo;
    @Column(nullable = false)
    private String meta;
    @Column(nullable = false)
    private String visibilidad;
    @Column(name = "esta_completado", nullable = false)
    private boolean estaCompletado;
    @Column(name = "fecha_inicio", nullable = false)
    private Instant fechaInicio;
    @Column(name = "fecha_fin", nullable = false)
    private Instant fechaFin;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "actualizado_en", nullable = false)
    private Instant actualizadoEn;
    @Column(name = "racha_actual", nullable = false)
    private int rachaActual;
    @Column(name = "mejor_racha", nullable = false)
    private int mejorRacha;
    @Column(name = "ultimo_dia_activo")
    private LocalDate ultimoDiaActivo;
    @Column(name = "tiene_dependencias", nullable = false)
    private boolean tieneDependencias;
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
    @Column(name = "sesiones_objetivo")
    private Integer sesionesObjetivo;
    @Column(name = "sesiones_completadas", nullable = false)
    private int sesionesCompletadas;
    @Column(name = "progreso_manual", nullable = false)
    private double progresoManual;
    @Column(name = "origen_id")
    private UUID origenId;
    @Column(name = "origen_propietario_id")
    private UUID origenPropietarioId;
    @Column(name = "origen_propietario_nombre")
    private String origenPropietarioNombre;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }
    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }
    public String getMeta() { return meta; }
    public void setMeta(String meta) { this.meta = meta; }
    public String getVisibilidad() { return visibilidad; }
    public void setVisibilidad(String visibilidad) { this.visibilidad = visibilidad; }
    public boolean isEstaCompletado() { return estaCompletado; }
    public void setEstaCompletado(boolean estaCompletado) { this.estaCompletado = estaCompletado; }
    public Instant getFechaInicio() { return fechaInicio; }
    public void setFechaInicio(Instant fechaInicio) { this.fechaInicio = fechaInicio; }
    public Instant getFechaFin() { return fechaFin; }
    public void setFechaFin(Instant fechaFin) { this.fechaFin = fechaFin; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant actualizadoEn) { this.actualizadoEn = actualizadoEn; }
    public int getRachaActual() { return rachaActual; }
    public void setRachaActual(int rachaActual) { this.rachaActual = rachaActual; }
    public int getMejorRacha() { return mejorRacha; }
    public void setMejorRacha(int mejorRacha) { this.mejorRacha = mejorRacha; }
    public LocalDate getUltimoDiaActivo() { return ultimoDiaActivo; }
    public void setUltimoDiaActivo(LocalDate ultimoDiaActivo) { this.ultimoDiaActivo = ultimoDiaActivo; }
    public boolean isTieneDependencias() { return tieneDependencias; }
    public void setTieneDependencias(boolean tieneDependencias) { this.tieneDependencias = tieneDependencias; }
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
    public Integer getSesionesObjetivo() { return sesionesObjetivo; }
    public void setSesionesObjetivo(Integer sesionesObjetivo) { this.sesionesObjetivo = sesionesObjetivo; }
    public int getSesionesCompletadas() { return sesionesCompletadas; }
    public void setSesionesCompletadas(int sesionesCompletadas) { this.sesionesCompletadas = sesionesCompletadas; }
    public double getProgresoManual() { return progresoManual; }
    public void setProgresoManual(double progresoManual) { this.progresoManual = progresoManual; }
    public UUID getOrigenId() { return origenId; }
    public void setOrigenId(UUID origenId) { this.origenId = origenId; }
    public UUID getOrigenPropietarioId() { return origenPropietarioId; }
    public void setOrigenPropietarioId(UUID origenPropietarioId) { this.origenPropietarioId = origenPropietarioId; }
    public String getOrigenPropietarioNombre() { return origenPropietarioNombre; }
    public void setOrigenPropietarioNombre(String origenPropietarioNombre) { this.origenPropietarioNombre = origenPropietarioNombre; }
}
