package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Duration;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Material de estudio: envuelve un apunte o un archivo (uno por usuario, tipo y origen) y
 * guarda su estado de repaso espaciado SM-2.
 */
public final class StudyMaterial {

    private final UUID id;
    private final UUID userId;
    private UUID subjectId;
    private final StudySourceType originType;
    private final UUID originId;
    private String title;
    private MasteryState masteryState;
    private Instant lastReviewedAt;
    private Instant nextReviewAt;
    private int intervalDays;
    private double easeFactor;
    private int completedReviews;
    private int failedReviews;
    private boolean practiceXpAwarded;
    private final Instant createdAt;

    private StudyMaterial(Builder b) {
        this.id = Objects.requireNonNull(b.id, "id");
        this.userId = Objects.requireNonNull(b.userId, "userId");
        this.subjectId = Guard.notNull(b.subjectId, "subjectId");
        this.originType = Guard.notNull(b.originType, "originType");
        this.originId = Guard.notNull(b.originId, "originId");
        this.title = Guard.length(b.title, "title", 1, 255);
        this.masteryState = b.masteryState == null ? MasteryState.NOT_EVALUATED : b.masteryState;
        this.lastReviewedAt = b.lastReviewedAt;
        this.nextReviewAt = b.nextReviewAt;
        this.intervalDays = Math.max(0, b.intervalDays);
        this.easeFactor = b.easeFactor <= 0 ? SpacedRepetition.INITIAL_EASE : b.easeFactor;
        this.completedReviews = Math.max(0, b.completedReviews);
        this.failedReviews = Math.max(0, b.failedReviews);
        this.practiceXpAwarded = b.practiceXpAwarded;
        this.createdAt = Objects.requireNonNull(b.createdAt, "createdAt");
    }

    public static Builder builder() {
        return new Builder();
    }

    public static StudyMaterial create(UUID userId, UUID subjectId, StudySourceType originType, UUID originId,
                                       String title, Instant now) {
        return builder().id(UUID.randomUUID()).userId(userId).subjectId(subjectId).originType(originType)
                .originId(originId).title(truncate(title)).createdAt(now).build();
    }

    private static String truncate(String title) {
        String t = title == null || title.isBlank() ? "Material de estudio" : title.strip();
        return t.length() > 255 ? t.substring(0, 255) : t;
    }

    /**
     * Calcula (sin aplicar) el resultado SM-2 de un repaso. Un acierto antes de tiempo no adelanta el
     * calendario: repasar tres veces seguidas no deja el material «dominado» (estado, intervalo y fecha
     * siguen como estaban). Un fallo cuenta siempre: indica que hay que volver a empezar.
     */
    public SpacedRepetition.Result simulate(int realQuality, double adjustedQuality, Instant now) {
        SpacedRepetition.Result r = SpacedRepetition.next(realQuality, adjustedQuality, intervalDays, easeFactor,
                completedReviews);
        if (!r.failed() && !isReviewOwed(now)) {
            return new SpacedRepetition.Result(intervalDays, easeFactor, completedReviews, masteryState, false);
        }
        return r;
    }

    /** Fecha del siguiente repaso si se aplica {@code r} en {@code now} (un acierto adelantado la conserva). */
    public Instant nextReviewAfter(SpacedRepetition.Result r, Instant now) {
        return r.failed() || isReviewOwed(now) ? now.plus(Duration.ofDays(r.intervalDays())) : nextReviewAt;
    }

    /** Aplica un repaso: actualiza dominio, intervalo, facilidad, contadores y la siguiente fecha. */
    public SpacedRepetition.Result review(int realQuality, double adjustedQuality, Instant now) {
        SpacedRepetition.Result r = simulate(realQuality, adjustedQuality, now);
        Instant next = nextReviewAfter(r, now);
        this.masteryState = r.masteryState();
        this.intervalDays = r.intervalDays();
        this.easeFactor = r.easeFactor();
        this.completedReviews = r.repetitions();
        if (r.failed()) {
            this.failedReviews++;
        }
        this.lastReviewedAt = now;
        this.nextReviewAt = next;
        return r;
    }

    public boolean isDue(Instant now) {
        return nextReviewAt != null && !nextReviewAt.isAfter(now);
    }

    /**
     * ¿Le toca un repaso? Vence su fecha SM-2 o nunca se ha repasado (el primer repaso está
     * pendiente). Solo los repasos que tocaban dan XP: tras repasar, la siguiente fecha queda al
     * menos a un día, así que repetir el repaso el mismo día no vuelve a puntuar (anti-farmeo).
     */
    public boolean isReviewOwed(Instant now) {
        return nextReviewAt == null || !nextReviewAt.isAfter(now);
    }

    /**
     * Lo quita del repaso: «abandonado» y sin fecha (la cola de repasos y los avisos lo ignoran). El historial
     * se conserva; un repaso posterior lo reactiva con el estado que resulte.
     */
    public void abandon() {
        this.masteryState = MasteryState.ABANDONED;
        this.nextReviewAt = null;
    }

    /** Registra que el material ya ha dado XP de práctica alguna vez (dato informativo). */
    public void markPracticeXpAwarded() {
        this.practiceXpAwarded = true;
    }

    public void retitle(String value) {
        this.title = truncate(value);
    }

    public void moveToSubject(UUID value) {
        this.subjectId = Guard.notNull(value, "subjectId");
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public UUID subjectId() { return subjectId; }
    public StudySourceType originType() { return originType; }
    public UUID originId() { return originId; }
    public String title() { return title; }
    public MasteryState masteryState() { return masteryState; }
    public Instant lastReviewedAt() { return lastReviewedAt; }
    public Instant nextReviewAt() { return nextReviewAt; }
    public int intervalDays() { return intervalDays; }
    public double easeFactor() { return easeFactor; }
    public int completedReviews() { return completedReviews; }
    public int failedReviews() { return failedReviews; }
    public boolean practiceXpAwarded() { return practiceXpAwarded; }
    public Instant createdAt() { return createdAt; }

    /** Constructor fluido para crear o reconstruir el material. */
    public static final class Builder {
        private UUID id;
        private UUID userId;
        private UUID subjectId;
        private StudySourceType originType;
        private UUID originId;
        private String title;
        private MasteryState masteryState;
        private Instant lastReviewedAt;
        private Instant nextReviewAt;
        private int intervalDays;
        private double easeFactor = SpacedRepetition.INITIAL_EASE;
        private int completedReviews;
        private int failedReviews;
        private boolean practiceXpAwarded;
        private Instant createdAt;

        public Builder id(UUID v) { this.id = v; return this; }
        public Builder userId(UUID v) { this.userId = v; return this; }
        public Builder subjectId(UUID v) { this.subjectId = v; return this; }
        public Builder originType(StudySourceType v) { this.originType = v; return this; }
        public Builder originId(UUID v) { this.originId = v; return this; }
        public Builder title(String v) { this.title = v; return this; }
        public Builder masteryState(MasteryState v) { this.masteryState = v; return this; }
        public Builder lastReviewedAt(Instant v) { this.lastReviewedAt = v; return this; }
        public Builder nextReviewAt(Instant v) { this.nextReviewAt = v; return this; }
        public Builder intervalDays(int v) { this.intervalDays = v; return this; }
        public Builder easeFactor(double v) { this.easeFactor = v; return this; }
        public Builder completedReviews(int v) { this.completedReviews = v; return this; }
        public Builder failedReviews(int v) { this.failedReviews = v; return this; }
        public Builder practiceXpAwarded(boolean v) { this.practiceXpAwarded = v; return this; }
        public Builder createdAt(Instant v) { this.createdAt = v; return this; }

        public StudyMaterial build() {
            return new StudyMaterial(this);
        }
    }
}
