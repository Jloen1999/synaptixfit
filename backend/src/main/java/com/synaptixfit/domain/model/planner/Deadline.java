package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Entrega, examen, presentación u otra evaluación con fecha límite.
 *
 * <p>Completarla da {@link #EXPERIENCE} puntos una sola vez mientras siga completada
 * ({@code xp_entrega_otorgado}); al desmarcarla se restan. Como mucho {@value #MAX_REWARDED_PER_DAY}
 * entregas dan XP cada 24 h: crear y completar entregas en serie daba XP sin límite.
 */
public final class Deadline {

    public static final int EXPERIENCE = 30;
    public static final int MAX_REWARDED_PER_DAY = 5;
    public static final int TITLE_MAX = 200;
    public static final int DESCRIPTION_MAX = 2000;

    private final UUID id;
    private final UUID userId;
    private UUID subjectId;
    private String title;
    private DeadlineType type;
    private Instant dueAt;
    private Priority difficulty;
    private String description;
    private boolean completed;
    private UUID studyPlanId;
    private boolean xpAwarded;
    private final String icsUid;
    private final Instant createdAt;
    private Instant updatedAt;

    private Deadline(Builder b) {
        this.id = Objects.requireNonNull(b.id, "id");
        this.userId = Objects.requireNonNull(b.userId, "userId");
        this.subjectId = b.subjectId;
        this.title = validTitle(b.title);
        this.type = b.type == null ? DeadlineType.ASSIGNMENT : b.type;
        this.dueAt = Guard.notNull(b.dueAt, "dueAt");
        this.difficulty = b.difficulty == null ? Priority.MEDIUM : b.difficulty;
        this.description = validDescription(b.description);
        this.completed = b.completed;
        this.studyPlanId = b.studyPlanId;
        this.xpAwarded = b.xpAwarded;
        this.icsUid = b.icsUid;
        this.createdAt = b.createdAt;
        this.updatedAt = b.updatedAt;
    }

    public static Builder builder() {
        return new Builder();
    }

    /** Edita los datos; los nulos se conservan. */
    public void update(String newTitle, DeadlineType newType, Instant newDueAt, Priority newDifficulty,
                       String newDescription, UUID newSubjectId, boolean clearSubject, Instant now) {
        if (newTitle != null) {
            this.title = validTitle(newTitle);
        }
        if (newType != null) {
            this.type = newType;
        }
        if (newDueAt != null) {
            this.dueAt = newDueAt;
        }
        if (newDifficulty != null) {
            this.difficulty = newDifficulty;
        }
        if (newDescription != null) {
            this.description = validDescription(newDescription);
        }
        if (clearSubject) {
            this.subjectId = null;
        } else if (newSubjectId != null) {
            this.subjectId = newSubjectId;
        }
        this.updatedAt = now;
    }

    /** @return true si el estado ha cambiado */
    public boolean setCompleted(boolean value, Instant now) {
        if (completed == value) {
            return false;
        }
        this.completed = value;
        this.updatedAt = now;
        return true;
    }

    /**
     * ¿Puede dar XP si ya dieron {@code rewardedLastDay} entregas en las últimas 24 h? Se cuentan por su última
     * modificación (no hay fecha de compleción): editar una entrega antigua solo puede restar margen, nunca
     * dar XP de más.
     */
    public static boolean fitsDailyCap(long rewardedLastDay) {
        return rewardedLastDay < MAX_REWARDED_PER_DAY;
    }

    public void markExperienceAwarded(boolean awarded) {
        this.xpAwarded = awarded;
    }

    public void attachToPlan(UUID planId) {
        this.studyPlanId = planId;
    }

    private static String validTitle(String value) {
        return Guard.length(value, "title", 1, TITLE_MAX);
    }

    private static String validDescription(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String v = value.strip();
        if (v.length() > DESCRIPTION_MAX) {
            throw new FieldValidationException("description", "INVALID_LENGTH",
                    "description must have at most " + DESCRIPTION_MAX + " characters");
        }
        return v;
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public UUID subjectId() { return subjectId; }
    public String title() { return title; }
    public DeadlineType type() { return type; }
    public Instant dueAt() { return dueAt; }

    /** Pendiente, hecha o vencida (sin completar y con la fecha pasada) respecto a {@code now}. */
    public ItemTimeStatus timeStatus(Instant now) {
        return ItemTimeStatus.ofDeadline(dueAt, completed, now);
    }
    public Priority difficulty() { return difficulty; }
    public String description() { return description; }
    public boolean completed() { return completed; }
    public UUID studyPlanId() { return studyPlanId; }
    public boolean xpAwarded() { return xpAwarded; }
    public String icsUid() { return icsUid; }
    public Instant createdAt() { return createdAt; }
    public Instant updatedAt() { return updatedAt; }

    /** Constructor fluido para crear o reconstruir la entrega. */
    public static final class Builder {
        private UUID id;
        private UUID userId;
        private UUID subjectId;
        private String title;
        private DeadlineType type;
        private Instant dueAt;
        private Priority difficulty;
        private String description;
        private boolean completed;
        private UUID studyPlanId;
        private boolean xpAwarded;
        private String icsUid;
        private Instant createdAt;
        private Instant updatedAt;

        public Builder id(UUID v) { this.id = v; return this; }
        public Builder userId(UUID v) { this.userId = v; return this; }
        public Builder subjectId(UUID v) { this.subjectId = v; return this; }
        public Builder title(String v) { this.title = v; return this; }
        public Builder type(DeadlineType v) { this.type = v; return this; }
        public Builder dueAt(Instant v) { this.dueAt = v; return this; }
        public Builder difficulty(Priority v) { this.difficulty = v; return this; }
        public Builder description(String v) { this.description = v; return this; }
        public Builder completed(boolean v) { this.completed = v; return this; }
        public Builder studyPlanId(UUID v) { this.studyPlanId = v; return this; }
        public Builder xpAwarded(boolean v) { this.xpAwarded = v; return this; }
        public Builder icsUid(String v) { this.icsUid = v; return this; }
        public Builder createdAt(Instant v) { this.createdAt = v; return this; }
        public Builder updatedAt(Instant v) { this.updatedAt = v; return this; }

        public Deadline build() {
            return new Deadline(this);
        }
    }
}
