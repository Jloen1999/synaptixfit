package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Plan semanal de entrenamiento (uno por usuario y semana). La semana se identifica por su lunes:
 * cualquier fecha se normaliza al lunes de su semana ISO.
 */
public final class WeeklyTrainingPlan {

    private final UUID id;
    private final UUID userId;
    private final LocalDate weekStart;
    private int plannedSessions;
    private PlanIntensity intensity;
    private int minutesPerSession;
    private PlanStatus status;
    private String notes;

    public WeeklyTrainingPlan(UUID id, UUID userId, LocalDate weekStart, int plannedSessions,
                              PlanIntensity intensity, int minutesPerSession, PlanStatus status, String notes) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.weekStart = mondayOf(Guard.notNull(weekStart, "weekStart"));
        apply(new Values(plannedSessions, intensity, minutesPerSession, status, notes));
    }

    public static WeeklyTrainingPlan create(UUID userId, LocalDate anyDayOfWeek, Values values) {
        Values v = values;
        return new WeeklyTrainingPlan(UUID.randomUUID(), userId, anyDayOfWeek, v.plannedSessions(), v.intensity(),
                v.minutesPerSession(), v.status(), v.notes());
    }

    public static LocalDate mondayOf(LocalDate date) {
        return date.with(DayOfWeek.MONDAY);
    }

    public void apply(Values v) {
        this.plannedSessions = Guard.range(v.plannedSessions(), "plannedSessions", 1, 7);
        this.intensity = v.intensity() == null ? PlanIntensity.MODERATE : v.intensity();
        this.minutesPerSession = Guard.range(v.minutesPerSession(), "minutesPerSession", 10, 180);
        this.status = v.status() == null ? PlanStatus.ACTIVE : v.status();
        String n = v.notes() == null || v.notes().isBlank() ? null : v.notes().strip();
        if (n != null && n.length() > 1000) {
            throw new FieldValidationException("notes", "INVALID_LENGTH", "notes length must be at most 1000");
        }
        this.notes = n;
    }

    /** Cumplimiento 0-1 dadas las sesiones completadas en la semana. */
    public double compliance(int completedSessions) {
        return Math.max(0, Math.min(1, (double) completedSessions / plannedSessions));
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public LocalDate weekStart() { return weekStart; }
    public int plannedSessions() { return plannedSessions; }
    public PlanIntensity intensity() { return intensity; }
    public int minutesPerSession() { return minutesPerSession; }
    public PlanStatus status() { return status; }
    public String notes() { return notes; }

    /** Valores editables del plan. */
    public record Values(int plannedSessions, PlanIntensity intensity, int minutesPerSession, PlanStatus status,
                         String notes) {
    }
}
