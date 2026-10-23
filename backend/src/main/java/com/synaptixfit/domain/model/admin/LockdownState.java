package com.synaptixfit.domain.model.admin;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Modo bloqueo de la plataforma: mientras está activo, las cuentas nuevas nacen ocultas
 * (shadowban). Guarda quién y cuándo lo activó.
 */
public final class LockdownState {

    private boolean active;
    private Instant startedAt;
    private UUID startedBy;
    private Instant updatedAt;

    public LockdownState(boolean active, Instant startedAt, UUID startedBy, Instant updatedAt) {
        this.active = active;
        this.startedAt = active ? startedAt : null;
        this.startedBy = active ? startedBy : null;
        this.updatedAt = updatedAt;
    }

    /**
     * Cambia el estado. Devuelve {@code false} si ya estaba en el estado pedido: no hay cambio,
     * no se audita y no se sobrescribe quién lo inició.
     */
    public boolean switchTo(boolean activate, UUID adminId, Instant now) {
        Objects.requireNonNull(now, "now");
        if (activate == active) {
            return false;
        }
        active = activate;
        startedAt = activate ? now : null;
        startedBy = activate ? adminId : null;
        updatedAt = now;
        return true;
    }

    public boolean active() { return active; }
    public Instant startedAt() { return startedAt; }
    public UUID startedBy() { return startedBy; }
    public Instant updatedAt() { return updatedAt; }
}
