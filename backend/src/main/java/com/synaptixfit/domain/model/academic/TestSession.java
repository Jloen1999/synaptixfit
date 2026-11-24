package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.academic.QuestionAlreadyAnsweredException;
import com.synaptixfit.domain.exception.academic.QuestionNotFoundException;
import com.synaptixfit.domain.exception.academic.TestSessionNotInProgressException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * Sesión de test persistente (práctica o simulacro cronometrado) sobre un subconjunto fijo de
 * preguntas. Se puede reanudar mientras está en curso; al completarse, la puntuación es el
 * número de aciertos. Solo una sesión completada con todas las preguntas respondidas da XP.
 *
 * <p>«No lo sé» (ADR 0063) es una respuesta más: cuenta como fallo y la pregunta vuelve antes. Al entregar, las
 * que quedaron sin contestar pasan a «No lo sé» ({@link #unansweredAtSubmit()}), pero no cuentan como
 * respondidas para la XP. Una sesión entregada sin ninguna respuesta no cuenta ({@link #countsIfSubmitted()}).
 */
public final class TestSession {

    private final UUID id;
    private final UUID userId;
    private final UUID materialId;
    private final List<UUID> questionIds;
    private final Map<UUID, String> answers;
    private final Map<UUID, Boolean> results;
    private final Set<UUID> dontKnow;
    private final Set<UUID> unansweredAtSubmit;
    private int currentIndex;
    private TestSessionStatus status;
    private final Instant startedAt;
    private Instant completedAt;
    private boolean xpAwarded;

    public TestSession(UUID id, UUID userId, UUID materialId, List<UUID> questionIds, Map<UUID, String> answers,
                       Map<UUID, Boolean> results, int currentIndex, TestSessionStatus status, Instant startedAt,
                       Instant completedAt, boolean xpAwarded) {
        this(id, userId, materialId, questionIds, answers, results, Set.of(), Set.of(), currentIndex, status,
                startedAt, completedAt, xpAwarded);
    }

    public TestSession(UUID id, UUID userId, UUID materialId, List<UUID> questionIds, Map<UUID, String> answers,
                       Map<UUID, Boolean> results, Set<UUID> dontKnow, Set<UUID> unansweredAtSubmit,
                       int currentIndex, TestSessionStatus status, Instant startedAt, Instant completedAt,
                       boolean xpAwarded) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.materialId = Objects.requireNonNull(materialId, "materialId");
        this.questionIds = List.copyOf(questionIds);
        this.answers = new LinkedHashMap<>(answers == null ? Map.of() : answers);
        this.results = new LinkedHashMap<>(results == null ? Map.of() : results);
        this.dontKnow = new LinkedHashSet<>(dontKnow == null ? Set.of() : dontKnow);
        this.unansweredAtSubmit = new LinkedHashSet<>(unansweredAtSubmit == null ? Set.of() : unansweredAtSubmit);
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

    /**
     * Registra la respuesta a una pregunta de la sesión. Una pregunta ya corregida (o con «No lo sé») no se
     * puede volver a contestar: la persona ya ha visto la solución y cambiarla subiría la nota y la XP.
     */
    public void answer(UUID questionId, String answer, boolean correct, Integer nextIndex) {
        int position = unansweredPositionOf(questionId);
        answers.put(questionId, answer == null ? "" : answer);
        results.put(questionId, correct);
        moveTo(nextIndex, position);
    }

    /** «No lo sé»: la pregunta queda respondida como fallo y volverá antes. Tampoco cambia una ya corregida. */
    public void dontKnow(UUID questionId, Integer nextIndex) {
        int position = unansweredPositionOf(questionId);
        answers.put(questionId, "");
        results.put(questionId, false);
        dontKnow.add(questionId);
        moveTo(nextIndex, position);
    }

    /**
     * Si al entregarla contaría: hace falta al menos una respuesta (o un «No lo sé»). Una sesión entregada sin
     * ninguna se abandona ({@link #abandon}): no da nota, ni XP, ni queda en el historial, ni toca el repaso.
     */
    public boolean countsIfSubmitted() {
        return !results.isEmpty();
    }

    /** Si cuenta: una sesión abandonada nunca da nota ni XP. */
    public boolean counted() {
        return status != TestSessionStatus.ABANDONED;
    }

    /**
     * Si sale en el historial: las en curso y las que tienen alguna respuesta. Una abandonada sin respuestas (un
     * simulacro entregado vacío) no.
     */
    public boolean inHistory() {
        return status == TestSessionStatus.IN_PROGRESS || countsIfSubmitted();
    }

    /**
     * Entrega la sesión. Las preguntas sin contestar pasan a «No lo sé» (fallo, y vuelven antes); devuelve cuáles,
     * para registrar su intento. Para la XP no cuentan como respondidas.
     */
    public List<UUID> complete(Instant now) {
        requireInProgress();
        List<UUID> filled = new ArrayList<>();
        for (UUID id : questionIds) {
            if (!results.containsKey(id)) {
                answers.put(id, "");
                results.put(id, false);
                dontKnow.add(id);
                unansweredAtSubmit.add(id);
                filled.add(id);
            }
        }
        this.status = TestSessionStatus.COMPLETED;
        this.completedAt = now;
        this.currentIndex = questionIds.size();
        return filled;
    }

    public void abandon(Instant now) {
        requireInProgress();
        this.status = TestSessionStatus.ABANDONED;
        this.completedAt = now;
    }

    public boolean allAnswered() {
        return !questionIds.isEmpty() && questionIds.stream().allMatch(results::containsKey);
    }

    /** Preguntas que contestó la persona (con una respuesta o con «No lo sé»), sin las rellenadas al entregar. */
    public int answeredCount() {
        return results.size() - unansweredAtSubmit.size();
    }

    /**
     * ¿Puede dar XP? Una sola vez y solo si se completó respondiendo la persona todas las preguntas (un «No lo sé»
     * suyo cuenta; las que se rellenaron al entregar, no).
     */
    public boolean canClaimXp() {
        return !xpAwarded && status == TestSessionStatus.COMPLETED && allAnswered() && unansweredAtSubmit.isEmpty();
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

    private int unansweredPositionOf(UUID questionId) {
        requireInProgress();
        int position = questionIds.indexOf(questionId);
        if (position < 0) {
            throw new QuestionNotFoundException(questionId);
        }
        if (results.containsKey(questionId)) {
            throw new QuestionAlreadyAnsweredException(questionId);
        }
        return position;
    }

    private void moveTo(Integer nextIndex, int position) {
        int target = nextIndex != null ? nextIndex : position + 1;
        this.currentIndex = Math.max(0, Math.min(target, questionIds.size()));
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
    /** Preguntas con «No lo sé» (dicho por la persona o puesto al entregar). */
    public Set<UUID> dontKnowIds() { return Set.copyOf(dontKnow); }
    /** Preguntas que seguían sin contestar al entregar (pasaron a «No lo sé»). */
    public Set<UUID> unansweredAtSubmit() { return Set.copyOf(unansweredAtSubmit); }
    public int currentIndex() { return currentIndex; }
    public TestSessionStatus status() { return status; }
    public Instant startedAt() { return startedAt; }
    public Instant completedAt() { return completedAt; }
    public boolean xpAwarded() { return xpAwarded; }
}
