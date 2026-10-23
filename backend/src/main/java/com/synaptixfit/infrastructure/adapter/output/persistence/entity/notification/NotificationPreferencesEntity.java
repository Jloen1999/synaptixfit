package com.synaptixfit.infrastructure.adapter.output.persistence.entity.notification;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalTime;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Tabla {@code preferencias_notificacion}. */
@Entity
@Table(name = "preferencias_notificacion")
public class NotificationPreferencesEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID usuarioId;
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "categorias_activas", nullable = false)
    private String[] categoriasActivas;
    @Column(name = "hora_silencio_inicio")
    private LocalTime horaSilencioInicio;
    @Column(name = "hora_silencio_fin")
    private LocalTime horaSilencioFin;
    @Column(name = "limite_diario", nullable = false)
    private int limiteDiario;
    @Column(name = "modo_actual", nullable = false)
    private String modoActual;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "actualizado_en", nullable = false)
    private Instant actualizadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public String[] getCategoriasActivas() { return categoriasActivas; }
    public void setCategoriasActivas(String[] categoriasActivas) { this.categoriasActivas = categoriasActivas; }
    public LocalTime getHoraSilencioInicio() { return horaSilencioInicio; }
    public void setHoraSilencioInicio(LocalTime horaSilencioInicio) { this.horaSilencioInicio = horaSilencioInicio; }
    public LocalTime getHoraSilencioFin() { return horaSilencioFin; }
    public void setHoraSilencioFin(LocalTime horaSilencioFin) { this.horaSilencioFin = horaSilencioFin; }
    public int getLimiteDiario() { return limiteDiario; }
    public void setLimiteDiario(int limiteDiario) { this.limiteDiario = limiteDiario; }
    public String getModoActual() { return modoActual; }
    public void setModoActual(String modoActual) { this.modoActual = modoActual; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant actualizadoEn) { this.actualizadoEn = actualizadoEn; }
}
