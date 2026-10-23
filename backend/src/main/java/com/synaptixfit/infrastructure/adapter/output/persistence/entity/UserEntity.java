package com.synaptixfit.infrastructure.adapter.output.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code usuarios}. */
@Entity
@Table(name = "usuarios")
public class UserEntity {

    @Id
    private UUID id;
    @Column(nullable = false)
    private String email;
    @Column(name = "password_hash")
    private String passwordHash;
    @Column(name = "google_sub")
    private String googleSub;
    @Column(name = "nombre_completo", nullable = false)
    private String nombreCompleto;
    @Column(name = "url_avatar")
    private String urlAvatar;
    @Column(nullable = false)
    private int nivel;
    @Column(name = "xp_nivel_actual", nullable = false)
    private int xpNivelActual;
    @Column(name = "racha_actual", nullable = false)
    private int rachaActual;
    @Column(name = "nivel_privacidad", nullable = false)
    private String nivelPrivacidad;
    @Column(nullable = false)
    private String rol;
    @Column(name = "is_shadowbanned", nullable = false)
    private boolean shadowbanned;
    @Column(name = "enfoque")
    private String enfoque;
    @Column(name = "onboarding_completado", nullable = false)
    private boolean onboardingCompletado;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "actualizado_en", nullable = false)
    private Instant actualizadoEn;
    @Column(name = "eliminado_en")
    private Instant eliminadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
    public String getGoogleSub() { return googleSub; }
    public void setGoogleSub(String googleSub) { this.googleSub = googleSub; }
    public String getNombreCompleto() { return nombreCompleto; }
    public void setNombreCompleto(String nombreCompleto) { this.nombreCompleto = nombreCompleto; }
    public String getUrlAvatar() { return urlAvatar; }
    public void setUrlAvatar(String urlAvatar) { this.urlAvatar = urlAvatar; }
    public int getNivel() { return nivel; }
    public void setNivel(int nivel) { this.nivel = nivel; }
    public int getXpNivelActual() { return xpNivelActual; }
    public void setXpNivelActual(int xpNivelActual) { this.xpNivelActual = xpNivelActual; }
    public int getRachaActual() { return rachaActual; }
    public void setRachaActual(int rachaActual) { this.rachaActual = rachaActual; }
    public String getNivelPrivacidad() { return nivelPrivacidad; }
    public void setNivelPrivacidad(String nivelPrivacidad) { this.nivelPrivacidad = nivelPrivacidad; }
    public String getRol() { return rol; }
    public void setRol(String rol) { this.rol = rol; }
    public boolean isShadowbanned() { return shadowbanned; }
    public void setShadowbanned(boolean shadowbanned) { this.shadowbanned = shadowbanned; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant actualizadoEn) { this.actualizadoEn = actualizadoEn; }
    public Instant getEliminadoEn() { return eliminadoEn; }
    public void setEliminadoEn(Instant eliminadoEn) { this.eliminadoEn = eliminadoEn; }

    public String getEnfoque() { return enfoque; }
    public void setEnfoque(String enfoque) { this.enfoque = enfoque; }
    public boolean isOnboardingCompletado() { return onboardingCompletado; }
    public void setOnboardingCompletado(boolean onboardingCompletado) { this.onboardingCompletado = onboardingCompletado; }
}
