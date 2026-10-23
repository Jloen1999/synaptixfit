package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.training.RecommendationAlreadyAppliedException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * Sugerencia de entrenamiento pendiente (progresión, degradación, descarga…). Puede llevar ajustes
 * concretos sobre ejercicios de una rutina; aplicarla los copia a la rutina. Descartarla la borra.
 */
public final class Recommendation {

    private final UUID id;
    private final UUID userId;
    private final RecommendationType type;
    private final String title;
    private final String description;
    private final UUID exerciseId;
    private final UUID routineId;
    private final List<ExerciseAdjustment> adjustments;
    private final Map<String, Object> details;
    private boolean applied;
    private final Instant createdAt;

    public Recommendation(UUID id, UUID userId, RecommendationType type, String title, String description,
                          UUID exerciseId, UUID routineId, List<ExerciseAdjustment> adjustments,
                          Map<String, Object> details, boolean applied, Instant createdAt) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.type = Guard.notNull(type, "type");
        this.title = Guard.length(title, "title", 1, 200);
        this.description = description;
        this.exerciseId = exerciseId;
        this.routineId = routineId;
        this.adjustments = List.copyOf(adjustments == null ? List.of() : adjustments);
        this.details = details == null ? Map.of() : Map.copyOf(details);
        this.applied = applied;
        this.createdAt = createdAt;
    }

    public static Recommendation create(UUID userId, RecommendationType type, String title, String description,
                                        UUID routineId, List<ExerciseAdjustment> adjustments,
                                        Map<String, Object> details, Instant now) {
        List<ExerciseAdjustment> list = adjustments == null ? List.of() : adjustments;
        UUID exerciseId = list.size() == 1 ? list.getFirst().exerciseId() : null;
        return new Recommendation(UUID.randomUUID(), userId, type, title, description, exerciseId, routineId,
                list, details, false, now);
    }

    public void markApplied() {
        if (applied) {
            throw new RecommendationAlreadyAppliedException();
        }
        applied = true;
    }

    public boolean isOwnedBy(UUID uid) {
        return userId.equals(uid);
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public RecommendationType type() { return type; }
    public String title() { return title; }
    public String description() { return description; }
    public UUID exerciseId() { return exerciseId; }
    public UUID routineId() { return routineId; }
    public List<ExerciseAdjustment> adjustments() { return adjustments; }
    public Map<String, Object> details() { return details; }
    public boolean applied() { return applied; }
    public Instant createdAt() { return createdAt; }
}
