package com.synaptixfit.domain.model.profile;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * Periodo durante el que el usuario tuvo un objetivo principal. Solo puede haber un periodo
 * abierto ({@code endDate == null}) por usuario: al cambiar de objetivo se cierra y se abre otro.
 */
public final class GoalHistoryEntry {

    private final UUID id;
    private final UUID userId;
    private final TrainingGoal goal;
    private final TrainingGoal previousGoal;
    private final LocalDate startDate;
    private LocalDate endDate;
    private final List<UUID> routineIds;
    private final Instant createdAt;

    public GoalHistoryEntry(UUID id, UUID userId, TrainingGoal goal, TrainingGoal previousGoal, LocalDate startDate,
                            LocalDate endDate, List<UUID> routineIds, Instant createdAt) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.goal = Objects.requireNonNull(goal, "goal");
        this.previousGoal = previousGoal;
        this.startDate = Objects.requireNonNull(startDate, "startDate");
        this.endDate = endDate;
        this.routineIds = routineIds == null ? List.of() : List.copyOf(routineIds);
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
    }

    /** Abre un periodo nuevo a partir de hoy. */
    public static GoalHistoryEntry open(UUID userId, TrainingGoal goal, TrainingGoal previousGoal, LocalDate today,
                                        Instant now) {
        return new GoalHistoryEntry(UUID.randomUUID(), userId, goal, previousGoal, today, null, List.of(), now);
    }

    /** Cierra el periodo. La fecha de fin nunca queda antes de la de inicio. */
    public void close(LocalDate date) {
        this.endDate = date.isBefore(startDate) ? startDate : date;
    }

    public boolean isOpen() {
        return endDate == null;
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public TrainingGoal goal() { return goal; }
    public TrainingGoal previousGoal() { return previousGoal; }
    public LocalDate startDate() { return startDate; }
    public LocalDate endDate() { return endDate; }
    public List<UUID> routineIds() { return routineIds; }
    public Instant createdAt() { return createdAt; }
}
