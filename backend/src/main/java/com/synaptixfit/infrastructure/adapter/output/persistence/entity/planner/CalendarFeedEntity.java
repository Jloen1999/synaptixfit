package com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code suscripciones_calendario} (V960): una suscripción por usuario, con la huella del token. */
@Entity
@Table(name = "suscripciones_calendario")
public class CalendarFeedEntity {

    @Id
    @Column(name = "usuario_id")
    private UUID usuarioId;
    @Column(name = "token_hash", nullable = false, length = 64)
    private String tokenHash;
    @Column(name = "creado_en", nullable = false)
    private Instant creadoEn;

    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public String getTokenHash() { return tokenHash; }
    public void setTokenHash(String tokenHash) { this.tokenHash = tokenHash; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
}
