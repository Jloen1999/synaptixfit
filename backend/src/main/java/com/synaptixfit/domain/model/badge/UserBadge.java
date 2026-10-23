package com.synaptixfit.domain.model.badge;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/** Insignia obtenida por un usuario. */
public final class UserBadge {

    private final UUID id;
    private final UUID userId;
    private final UUID badgeId;
    private final Instant earnedAt;
    private boolean notified;
    private boolean visible;

    public UserBadge(UUID id, UUID userId, UUID badgeId, Instant earnedAt, boolean notified, boolean visible) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.badgeId = Objects.requireNonNull(badgeId, "badgeId");
        this.earnedAt = Objects.requireNonNull(earnedAt, "earnedAt");
        this.notified = notified;
        this.visible = visible;
    }

    /** Insignia recién obtenida: visible y pendiente de notificar. */
    public static UserBadge earn(UUID userId, UUID badgeId, Instant when) {
        return new UserBadge(UUID.randomUUID(), userId, badgeId, when, false, true);
    }

    public void markNotified() {
        this.notified = true;
    }

    public void changeVisibility(boolean newVisible) {
        this.visible = newVisible;
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public UUID badgeId() { return badgeId; }
    public Instant earnedAt() { return earnedAt; }
    public boolean notified() { return notified; }
    public boolean visible() { return visible; }
}
