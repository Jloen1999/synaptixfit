package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Asignatura que cursa un estudiante (propia o creada desde el catálogo académico).
 *
 * <p>Invariantes: nombre de 2 a 150 caracteres, créditos 1-30 y dificultad percibida 1-5. El
 * enlace ICS ({@code icsUrl}) solo se guarda: la sincronización es del planificador.
 */
public final class Subject {

    public static final int DEFAULT_CREDITS = 3;
    public static final int DEFAULT_DIFFICULTY = 3;

    private final UUID id;
    private final UUID userId;
    private String name;
    private String code;
    private String description;
    private int credits;
    private int perceivedDifficulty;
    private SubjectPriority priority;
    private Instant nextAssessmentAt;
    private String teacher;
    private String room;
    private boolean archived;
    private final UUID catalogSubjectId;
    private String icsUrl;
    private final Instant lastSyncedAt;
    private final Instant createdAt;

    private Subject(Builder b) {
        this.id = Objects.requireNonNull(b.id, "id");
        this.userId = Objects.requireNonNull(b.userId, "userId");
        this.name = Guard.length(b.name, "name", 2, 150);
        this.code = TextRules.optional(b.code, "code", 50);
        this.description = TextRules.optional(b.description, "description", 2000);
        this.credits = Guard.range(b.credits, "credits", 1, 30);
        this.perceivedDifficulty = Guard.range(b.perceivedDifficulty, "perceivedDifficulty", 1, 5);
        this.priority = b.priority == null ? SubjectPriority.MEDIUM : b.priority;
        this.nextAssessmentAt = b.nextAssessmentAt;
        this.teacher = TextRules.optional(b.teacher, "teacher", 150);
        this.room = TextRules.optional(b.room, "room", 100);
        this.archived = b.archived;
        this.catalogSubjectId = b.catalogSubjectId;
        this.icsUrl = TextRules.optional(b.icsUrl, "icsUrl", 2048);
        this.lastSyncedAt = b.lastSyncedAt;
        this.createdAt = Objects.requireNonNull(b.createdAt, "createdAt");
    }

    public static Builder builder() {
        return new Builder();
    }

    public void rename(String newName) {
        this.name = Guard.length(newName, "name", 2, 150);
    }

    public void changeCode(String value) {
        this.code = TextRules.optional(value, "code", 50);
    }

    public void changeDescription(String value) {
        this.description = TextRules.optional(value, "description", 2000);
    }

    public void changeCredits(int value) {
        this.credits = Guard.range(value, "credits", 1, 30);
    }

    public void changePerceivedDifficulty(int value) {
        this.perceivedDifficulty = Guard.range(value, "perceivedDifficulty", 1, 5);
    }

    public void changePriority(SubjectPriority value) {
        this.priority = Guard.notNull(value, "priority");
    }

    public void scheduleNextAssessment(Instant value) {
        this.nextAssessmentAt = value;
    }

    public void changeTeacher(String value) {
        this.teacher = TextRules.optional(value, "teacher", 150);
    }

    /** Aula habitual (opcional): se usa si la próxima clase del horario no dice dónde es. */
    public void changeRoom(String value) {
        this.room = TextRules.optional(value, "room", 100);
    }

    public void changeIcsUrl(String value) {
        this.icsUrl = TextRules.optional(value, "icsUrl", 2048);
    }

    public void archive() {
        this.archived = true;
    }

    public void unarchive() {
        this.archived = false;
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public String name() { return name; }
    public String code() { return code; }
    public String description() { return description; }
    public int credits() { return credits; }
    public int perceivedDifficulty() { return perceivedDifficulty; }
    public SubjectPriority priority() { return priority; }
    public Instant nextAssessmentAt() { return nextAssessmentAt; }
    public String teacher() { return teacher; }
    public String room() { return room; }
    public boolean archived() { return archived; }
    public UUID catalogSubjectId() { return catalogSubjectId; }
    public String icsUrl() { return icsUrl; }
    public Instant lastSyncedAt() { return lastSyncedAt; }
    public Instant createdAt() { return createdAt; }

    /** Constructor fluido para crear o reconstruir la asignatura. */
    public static final class Builder {
        private UUID id;
        private UUID userId;
        private String name;
        private String code;
        private String description;
        private int credits = DEFAULT_CREDITS;
        private int perceivedDifficulty = DEFAULT_DIFFICULTY;
        private SubjectPriority priority;
        private Instant nextAssessmentAt;
        private String teacher;
        private String room;
        private boolean archived;
        private UUID catalogSubjectId;
        private String icsUrl;
        private Instant lastSyncedAt;
        private Instant createdAt;

        public Builder id(UUID v) { this.id = v; return this; }
        public Builder userId(UUID v) { this.userId = v; return this; }
        public Builder name(String v) { this.name = v; return this; }
        public Builder code(String v) { this.code = v; return this; }
        public Builder description(String v) { this.description = v; return this; }
        public Builder credits(int v) { this.credits = v; return this; }
        public Builder perceivedDifficulty(int v) { this.perceivedDifficulty = v; return this; }
        public Builder priority(SubjectPriority v) { this.priority = v; return this; }
        public Builder nextAssessmentAt(Instant v) { this.nextAssessmentAt = v; return this; }
        public Builder teacher(String v) { this.teacher = v; return this; }
        public Builder room(String v) { this.room = v; return this; }
        public Builder archived(boolean v) { this.archived = v; return this; }
        public Builder catalogSubjectId(UUID v) { this.catalogSubjectId = v; return this; }
        public Builder icsUrl(String v) { this.icsUrl = v; return this; }
        public Builder lastSyncedAt(Instant v) { this.lastSyncedAt = v; return this; }
        public Builder createdAt(Instant v) { this.createdAt = v; return this; }

        public Subject build() {
            return new Subject(this);
        }
    }
}
