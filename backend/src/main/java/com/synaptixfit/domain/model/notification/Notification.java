package com.synaptixfit.domain.model.notification;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Notificación in-app de un usuario, con enlace profundo opcional ({@code actionUrl}).
 * {@code referenceKey} (opcional, interna) identifica de forma estable el hecho avisado (p. ej.
 * {@code challenge:<id>}) para que los avisos automáticos no se repitan.
 */
public final class Notification {

    public static final int MAX_TITLE = 200;
    public static final int MAX_DESCRIPTION = 1000;
    public static final int MAX_ACTION_URL = 2048;
    public static final int MAX_ACTION_LABEL = 60;
    public static final int MAX_REFERENCE_KEY = 120;

    private final UUID id;
    private final UUID userId;
    private final String title;
    private final String description;
    private final NotificationPriority priority;
    private final NotificationType type;
    private final String actionUrl;
    private final String actionLabel;
    private final String referenceKey;
    private boolean read;
    private final Instant createdAt;
    private Instant readAt;

    public Notification(UUID id, UUID userId, String title, String description, NotificationPriority priority,
                        NotificationType type, String actionUrl, String actionLabel, String referenceKey,
                        boolean read, Instant createdAt, Instant readAt) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.title = Guard.length(title, "title", 1, MAX_TITLE);
        this.description = optional(description, "description", MAX_DESCRIPTION);
        this.priority = Guard.notNull(priority, "priority");
        this.type = Guard.notNull(type, "type");
        this.actionUrl = optional(actionUrl, "actionUrl", MAX_ACTION_URL);
        this.actionLabel = optional(actionLabel, "actionLabel", MAX_ACTION_LABEL);
        this.referenceKey = optional(referenceKey, "referenceKey", MAX_REFERENCE_KEY);
        this.read = read;
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
        this.readAt = readAt;
    }

    public static Notification create(UUID userId, String title, String description, NotificationPriority priority,
                                      NotificationType type, String actionUrl, String actionLabel, Instant now) {
        return create(userId, title, description, priority, type, actionUrl, actionLabel, null, now);
    }

    public static Notification create(UUID userId, String title, String description, NotificationPriority priority,
                                      NotificationType type, String actionUrl, String actionLabel,
                                      String referenceKey, Instant now) {
        return new Notification(UUID.randomUUID(), userId, title, description, priority, type, actionUrl,
                actionLabel, referenceKey, false, now, null);
    }

    public boolean belongsTo(UUID otherUserId) {
        return userId.equals(otherUserId);
    }

    /** Marca como leída. Idempotente: conserva la primera fecha de lectura. */
    public void markRead(Instant now) {
        if (!read) {
            this.read = true;
            this.readAt = now;
        }
    }

    private static String optional(String value, String field, int max) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return Guard.length(value, field, 1, max);
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public String title() { return title; }
    public String description() { return description; }
    public NotificationPriority priority() { return priority; }
    public NotificationType type() { return type; }
    public String actionUrl() { return actionUrl; }
    public String actionLabel() { return actionLabel; }
    public String referenceKey() { return referenceKey; }
    public boolean read() { return read; }
    public Instant createdAt() { return createdAt; }
    public Instant readAt() { return readAt; }
}
