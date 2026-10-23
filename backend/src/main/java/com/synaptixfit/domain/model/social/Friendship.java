package com.synaptixfit.domain.model.social;

import com.synaptixfit.domain.exception.social.FriendshipInvalidStateException;
import com.synaptixfit.domain.exception.social.FriendshipNotFoundException;
import com.synaptixfit.domain.exception.social.FriendshipSelfTargetException;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Relación entre dos usuarios (una sola fila por pareja, en cualquier sentido).
 *
 * <p>Máquina de estados: {@code PENDING -> ACCEPTED | REJECTED}; una solicitud rechazada puede
 * renovarse; cualquiera puede bloquear en cualquier momento. Convenio para el bloqueo: en estado
 * {@code BLOCKED} el solicitante ({@code requesterId}) es quien bloquea, y solo él puede
 * deshacerlo (borrando la relación). El bloqueado no ve la relación.
 */
public final class Friendship {

    private final UUID id;
    private UUID requesterId;
    private UUID addresseeId;
    private FriendshipStatus status;
    private final Instant createdAt;
    private Instant updatedAt;

    public Friendship(UUID id, UUID requesterId, UUID addresseeId, FriendshipStatus status, Instant createdAt,
                      Instant updatedAt) {
        this.id = Objects.requireNonNull(id, "id");
        this.requesterId = Objects.requireNonNull(requesterId, "requesterId");
        this.addresseeId = Objects.requireNonNull(addresseeId, "addresseeId");
        if (requesterId.equals(addresseeId)) {
            throw new FriendshipSelfTargetException(requesterId);
        }
        this.status = Objects.requireNonNull(status, "status");
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
        this.updatedAt = updatedAt == null ? createdAt : updatedAt;
    }

    public static Friendship request(UUID requesterId, UUID addresseeId, Instant now) {
        return new Friendship(UUID.randomUUID(), requesterId, addresseeId, FriendshipStatus.PENDING, now, now);
    }

    public static Friendship blocking(UUID blockerId, UUID blockedId, Instant now) {
        return new Friendship(UUID.randomUUID(), blockerId, blockedId, FriendshipStatus.BLOCKED, now, now);
    }

    public boolean involves(UUID userId) {
        return requesterId.equals(userId) || addresseeId.equals(userId);
    }

    public UUID otherThan(UUID userId) {
        return requesterId.equals(userId) ? addresseeId : requesterId;
    }

    public boolean isAccepted() {
        return status == FriendshipStatus.ACCEPTED;
    }

    public boolean isBlocked() {
        return status == FriendshipStatus.BLOCKED;
    }

    public boolean isBlockedBy(UUID userId) {
        return isBlocked() && requesterId.equals(userId);
    }

    /** ¿Puede {@code userId} ver esta relación? El bloqueado no la ve. */
    public boolean isVisibleTo(UUID userId) {
        return involves(userId) && (!isBlocked() || isBlockedBy(userId));
    }

    /** Acepta una solicitud recibida y pendiente. */
    public void accept(UUID userId, Instant now) {
        ensurePendingReceivedBy(userId);
        this.status = FriendshipStatus.ACCEPTED;
        this.updatedAt = now;
    }

    /** Rechaza una solicitud recibida y pendiente. */
    public void reject(UUID userId, Instant now) {
        ensurePendingReceivedBy(userId);
        this.status = FriendshipStatus.REJECTED;
        this.updatedAt = now;
    }

    /** Vuelve a pedir amistad sobre una relación rechazada (puede hacerlo cualquiera de los dos). */
    public void renewRequest(UUID newRequesterId, Instant now) {
        if (status != FriendshipStatus.REJECTED || !involves(newRequesterId)) {
            throw new FriendshipInvalidStateException(id);
        }
        UUID other = otherThan(newRequesterId);
        this.requesterId = newRequesterId;
        this.addresseeId = other;
        this.status = FriendshipStatus.PENDING;
        this.updatedAt = now;
    }

    /** Bloquea al otro usuario desde cualquier estado; el bloqueador pasa a ser el solicitante. */
    public void blockBy(UUID blockerId, Instant now) {
        if (!involves(blockerId) || (isBlocked() && !isBlockedBy(blockerId))) {
            throw new FriendshipInvalidStateException(id);
        }
        UUID other = otherThan(blockerId);
        this.requesterId = blockerId;
        this.addresseeId = other;
        this.status = FriendshipStatus.BLOCKED;
        this.updatedAt = now;
    }

    /**
     * Comprueba que {@code userId} puede borrar la relación (cancelar solicitud, eliminar amigo,
     * limpiar un rechazo o desbloquear). Un bloqueado ni siquiera la ve.
     */
    public void ensureRemovableBy(UUID userId) {
        if (!isVisibleTo(userId)) {
            throw new FriendshipNotFoundException(id);
        }
    }

    public FriendshipRelation relationFor(UUID viewerId) {
        return FriendshipRelation.of(viewerId, status, requesterId);
    }

    private void ensurePendingReceivedBy(UUID userId) {
        if (status != FriendshipStatus.PENDING || !addresseeId.equals(userId)) {
            throw new FriendshipInvalidStateException(id);
        }
    }

    public UUID id() { return id; }
    public UUID requesterId() { return requesterId; }
    public UUID addresseeId() { return addresseeId; }
    public FriendshipStatus status() { return status; }
    public Instant createdAt() { return createdAt; }
    public Instant updatedAt() { return updatedAt; }
}
