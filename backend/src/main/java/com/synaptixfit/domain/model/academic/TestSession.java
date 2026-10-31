package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.academic.QuestionNotFoundException;
import com.synaptixfit.domain.exception.academic.TestSessionNotInProgressException;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * Sesión de test persistente (práctica o simulacro cronometrado) sobre un subconjunto fijo de
 * preguntas. Se puede reanudar mientras está en curso; al completarse, la puntuación es el
 * número de aciertos. Solo una sesión completada con todas las preguntas respondidas da XP.
 */
public final class TestSession {

    private final UUID id;
    private final UUID userId;
    private final UUID materialId;
    private final List<UUID> questionIds;
    private final Map<UUID, String> answers;
    private final Map<UUID, Boolean> results;
    private int currentIndex;
    private TestSessionStatus status;
    private final Instant startedAt;
    private Instant completedAt;
    private boolean xpAwarded;

    public TestSession(UUID id, UUID userId, UUID materialId, List<UUID> questionIds, Map<UUID, String> answers,
                       Map<UUID, Boolean> results, int currentIndex, TestSessionStatus status, Instant startedAt,
                       Instant completedAt, boolean xpAwarded) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.materialId = Objects.requireNonNull(materialId, "materialId");
        this.questionIds = List.copyOf(questionIds);
        this.answers = new LinkedHashMap<>(answers == null ? Map.of() : answers);
        this.results = new LinkedHashMap<>(results == null ? Map.of() : results);
        this.currentIndex = Math.max(0, currentIndex);
        this.status = status == null ? TestSessionStatus.IN_PROGRESS : status;
        this.startedAt = Objects.requireNonNull(startedAt, "startedAt");
        this.completedAt = completedAt;
        this.xpAwarded = xpAwarded;
    }

    public static TestSession start(UUID userId, UUID materialId, List<UUID> questionIds, Instant now) {
        return new TestSession(UUID.randomUUID(), userId, materialId, questionIds, Map.of(), Map.of(), 0,
                TestSessionStatus.IN_PROGRESS, now, null, false);
    }

    /** Registra (o corrige) la respuesta a una pregunta de la sesión. */
    public void answer(UUID questionId, String answer, boolean correct, Integer nextIndex) {
        requireInProgress();
        int position = questionIds.indexOf(questionId);
        if (position < 0) {
            throw new QuestionNotFoundException(questionId);
        }
        answers.put(questionId, answer == null ? "" : answer);
        results.put(questionId, correct);
        int target = nextIndex != null ? nextIndex : position + 1;
        this.currentIndex = Math.max(0, Math.min(target, questionIds.size()));
    }

    public void complete(Instant now) {
        requireInProgress();
        this.status = TestSessionStatus.COMPLETED;
        this.completedAt = now;
        this.currentIndex = questionIds.size();
    }

    public void abandon(Instant now) {
        requireInProgress();
        this.status = TestSessionStatus.ABANDONED;
        this.completedAt = now;
    }

    public boolean allAnswered() {
        return !questionIds.isEmpty() && questionIds.stream().allMatch(results::containsKey);
    }

    /** ¿Puede dar XP? Una sola vez y solo si se completó respondiendo todas las preguntas. */
    public boolean canClaimXp() {
        return !xpAwarded && status == TestSessionStatus.COMPLETED && allAnswered();
    }

    /**
     * Concede la XP (si {@link #canClaimXp()}). Solo se marca cuando de verdad dio XP: así el tope de tests
     * con XP de {@code PracticeRewards} no cuenta los que no puntuaron.
     */
    public boolean claimXp() {
        if (!canClaimXp()) {
            return false;
        }
        xpAwarded = true;
        return true;
    }

    public int score() {
        return (int) results.values().stream().filter(Boolean::booleanValue).count();
    }

    public int totalQuestions() {
        return questionIds.size();
    }

    private void requireInProgress() {
        if (status != TestSessionStatus.IN_PROGRESS) {
            throw new TestSessionNotInProgressException(id);
        }
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public UUID materialId() { return materialId; }
    public List<UUID> questionIds() { return questionIds; }
    public Map<UUID, String> answers() { return Map.copyOf(answers); }
    public Map<UUID, Boolean> results() { return Map.copyOf(results); }
    public int currentIndex() { return currentIndex; }
    public TestSessionStatus status() { return status; }
    public Instant startedAt() { return startedAt; }
    public Instant completedAt() { return completedAt; }
    public boolean xpAwarded() { return xpAwarded; }
}
