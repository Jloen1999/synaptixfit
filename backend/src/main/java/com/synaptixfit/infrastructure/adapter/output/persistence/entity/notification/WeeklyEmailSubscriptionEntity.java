package com.synaptixfit.infrastructure.adapter.output.persistence.entity.notification;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Tabla {@code suscripciones_resumen_semanal} (V980). */
@Entity
@Table(name = "suscripciones_resumen_semanal")
public class WeeklyEmailSubscriptionEntity {

    @Id
    @Column(name = "usuario_id")
    private UUID usuarioId;
    @Column(name = "estado", nullable = false, length = 16)
    private String estado;
    @Column(name = "idioma", nullable = false, length = 5)
    private String idioma;
    @Column(name = "token_confirmacion_hash", length = 64)
    private String tokenConfirmacionHash;
    @Column(name = "token_baja", nullable = false, length = 64)
    private String tokenBaja;
    @Column(name = "ultima_semana_enviada")
    private LocalDate ultimaSemanaEnviada;
    @Column(name = "actualizado_en", nullable = false)
    private Instant actualizadoEn;

    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }
    public String getIdioma() { return idioma; }
    public void setIdioma(String idioma) { this.idioma = idioma; }
    public String getTokenConfirmacionHash() { return tokenConfirmacionHash; }
    public void setTokenConfirmacionHash(String v) { this.tokenConfirmacionHash = v; }
    public String getTokenBaja() { return tokenBaja; }
    public void setTokenBaja(String tokenBaja) { this.tokenBaja = tokenBaja; }
    public LocalDate getUltimaSemanaEnviada() { return ultimaSemanaEnviada; }
    public void setUltimaSemanaEnviada(LocalDate v) { this.ultimaSemanaEnviada = v; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant actualizadoEn) { this.actualizadoEn = actualizadoEn; }
}
