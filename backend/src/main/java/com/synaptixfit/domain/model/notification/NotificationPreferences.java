package com.synaptixfit.domain.model.notification;

import com.synaptixfit.domain.exception.notification.NotificationInvalidQuietHoursException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Collection;
import java.util.EnumSet;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * Preferencias de notificación de un usuario (una por usuario).
 *
 * <p>Reglas de entrega ({@link #evaluate}): las notificaciones {@code CRITICAL} siempre se
 * entregan. El resto debe tener su categoría activa, estar permitida por el modo, caer fuera de
 * las horas de silencio y no superar el límite diario.
 */
public final class NotificationPreferences {

    public static final int DEFAULT_DAILY_LIMIT = 10;
    public static final int MAX_DAILY_LIMIT = 50;

    private final UUID id;
    private final UUID userId;
    private Set<NotificationType> activeCategories;
    private LocalTime quietHoursStart;
    private LocalTime quietHoursEnd;
    private int dailyLimit;
    private NotificationMode mode;
    private final Instant createdAt;
    private Instant updatedAt;

    public NotificationPreferences(UUID id, UUID userId, Collection<NotificationType> activeCategories,
                                   LocalTime quietHoursStart, LocalTime quietHoursEnd, int dailyLimit,
                                   NotificationMode mode, Instant createdAt, Instant updatedAt) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
        apply(activeCategories, quietHoursStart, quietHoursEnd, dailyLimit, mode);
        this.updatedAt = updatedAt == null ? createdAt : updatedAt;
    }

    /** Preferencias por defecto: todas las categorías, sin horas de silencio, 10 al día, modo normal. */
    public static NotificationPreferences defaults(UUID userId, Instant now) {
        return new NotificationPreferences(UUID.randomUUID(), userId, EnumSet.allOf(NotificationType.class),
                null, null, DEFAULT_DAILY_LIMIT, NotificationMode.NORMAL, now, now);
    }

    public void update(Collection<NotificationType> categories, LocalTime start, LocalTime end, int limit,
                       NotificationMode newMode, Instant now) {
        apply(categories, start, end, limit, newMode);
        this.updatedAt = now;
    }

    /**
     * ¿Está {@code localTime} dentro de las horas de silencio? El intervalo es [inicio, fin) y
     * puede cruzar la medianoche (p. ej. 23:00-07:00).
     */
    public boolean inQuietHours(LocalTime localTime) {
        if (quietHoursStart == null) {
            return false;
        }
        if (quietHoursStart.isBefore(quietHoursEnd)) {
            return !localTime.isBefore(quietHoursStart) && localTime.isBefore(quietHoursEnd);
        }
        return !localTime.isBefore(quietHoursStart) || localTime.isBefore(quietHoursEnd);
    }

    /**
     * Primer momento fuera de las horas de silencio desde {@code at} (hora local): {@code at} si no cae
     * en silencio; si cae, el final del silencio de ese día o, si ya pasó, del siguiente. Lo usa el
     * plan de recordatorios: un aviso que se conoce de antemano aún sirve al terminar el silencio.
     */
    public LocalDateTime afterQuietHours(LocalDateTime at) {
        if (!inQuietHours(at.toLocalTime())) {
            return at;
        }
        LocalDateTime sameDay = at.toLocalDate().atTime(quietHoursEnd);
        return sameDay.isAfter(at) ? sameDay : sameDay.plusDays(1);
    }

    /** ¿Pasa una notificación no crítica de ese tipo por la categoría y el modo? (sin hora ni límite). */
    public boolean admits(NotificationType type) {
        return activeCategories.contains(type) && mode.allows(type);
    }

    /**
     * Decide si se entrega una notificación.
     *
     * @param localTime hora local del usuario
     * @param sentToday notificaciones ya creadas hoy para el usuario
     */
    public DeliveryDecision evaluate(NotificationType type, NotificationPriority priority, LocalTime localTime,
                                     long sentToday) {
        if (priority == NotificationPriority.CRITICAL) {
            return DeliveryDecision.DELIVER;
        }
        if (!activeCategories.contains(type)) {
            return DeliveryDecision.SUPPRESSED_CATEGORY;
        }
        if (!mode.allows(type)) {
            return DeliveryDecision.SUPPRESSED_MODE;
        }
        if (inQuietHours(localTime)) {
            return DeliveryDecision.SUPPRESSED_QUIET_HOURS;
        }
        if (sentToday >= dailyLimit) {
            return DeliveryDecision.SUPPRESSED_DAILY_LIMIT;
        }
        return DeliveryDecision.DELIVER;
    }

    private void apply(Collection<NotificationType> categories, LocalTime start, LocalTime end, int limit,
                       NotificationMode newMode) {
        Guard.notNull(categories, "activeCategories");
        if ((start == null) != (end == null) || (start != null && start.equals(end))) {
            throw new NotificationInvalidQuietHoursException();
        }
        this.activeCategories = categories.isEmpty()
                ? EnumSet.noneOf(NotificationType.class) : EnumSet.copyOf(categories);
        this.quietHoursStart = start;
        this.quietHoursEnd = end;
        this.dailyLimit = Guard.range(limit, "dailyLimit", 0, MAX_DAILY_LIMIT);
        this.mode = Guard.notNull(newMode, "mode");
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public Set<NotificationType> activeCategories() { return Set.copyOf(activeCategories); }
    public LocalTime quietHoursStart() { return quietHoursStart; }
    public LocalTime quietHoursEnd() { return quietHoursEnd; }
    public int dailyLimit() { return dailyLimit; }
    public NotificationMode mode() { return mode; }
    public Instant createdAt() { return createdAt; }
    public Instant updatedAt() { return updatedAt; }
}
