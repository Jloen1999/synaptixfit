package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.training.SessionAlreadyCompletedException;
import com.synaptixfit.domain.exception.training.SessionNotCompletedException;
import com.synaptixfit.domain.exception.training.SessionSetNotFoundException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * Sesión de entrenamiento. Está en curso mientras {@code completedAt} es nulo; al finalizarla se
 * fijan duración, RPE, calorías y la experiencia otorgada, que se guarda para poder restar
 * exactamente esa cantidad si se desmarca (anti-farmeo).
 */
public final class TrainingSession {

    private final UUID id;
    private final UUID userId;
    private final UUID routineId;
    private final UUID dayId;
    private final SessionType type;
    private final Instant startedAt;
    private Instant completedAt;
    private int durationMinutes;
    private Integer rpe;
    private Double calories;
    private int xpAwarded;
    private final List<SessionSet> sets;

    public TrainingSession(UUID id, UUID userId, UUID routineId, UUID dayId, SessionType type, Instant startedAt,
                           Instant completedAt, int durationMinutes, Integer rpe, Double calories, int xpAwarded,
                           List<SessionSet> sets) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.routineId = routineId;
        this.dayId = dayId;
        this.type = type == null ? SessionType.FREE : type;
        this.startedAt = Objects.requireNonNull(startedAt, "startedAt");
        this.completedAt = completedAt;
        this.durationMinutes = Math.max(0, durationMinutes);
        this.rpe = rpe;
        this.calories = calories;
        this.xpAwarded = Math.max(0, xpAwarded);
        this.sets = new ArrayList<>(sets == null ? List.of() : sets);
    }

    public static TrainingSession start(UUID userId, UUID routineId, UUID dayId, Instant now) {
        SessionType type = dayId == null ? SessionType.FREE : SessionType.ROUTINE;
        return new TrainingSession(UUID.randomUUID(), userId, routineId, dayId, type, now, null, 0, null, null, 0,
                List.of());
    }

    /** Registra (o sustituye) la serie {@code setNumber} del ejercicio planificado indicado. */
    public SessionSet recordSet(UUID plannedExerciseId, int setNumber, Integer repsDone, Double weightKg,
                                boolean completed, int failedReps) {
        ensureInProgress();
        sets.removeIf(s -> Objects.equals(s.plannedExerciseId(), plannedExerciseId) && s.setNumber() == setNumber);
        SessionSet set = new SessionSet(UUID.randomUUID(), plannedExerciseId, setNumber, repsDone, weightKg,
                completed, failedReps);
        sets.add(set);
        return set;
    }

    public void removeSet(UUID setId) {
        ensureInProgress();
        if (!sets.removeIf(s -> s.id().equals(setId))) {
            throw new SessionSetNotFoundException(setId);
        }
    }

    /** Finaliza la sesión. La duración se redondea a minutos (mínimo 1). */
    public void complete(long durationSeconds, int sessionRpe, double sessionCalories, int xp, Instant now) {
        ensureInProgress();
        Guard.range(sessionRpe, "rpe", 1, 10);
        Guard.range((double) durationSeconds, "durationSeconds", 1, 86_400);
        this.durationMinutes = minutesOf(durationSeconds);
        this.rpe = sessionRpe;
        this.calories = Math.round(sessionCalories * 10) / 10.0;
        this.xpAwarded = Math.max(0, xp);
        this.completedAt = Objects.requireNonNull(now);
    }

    /** Minutos de una duración en segundos, redondeados y como mínimo 1. */
    public static int minutesOf(long durationSeconds) {
        return (int) Math.max(1, Math.round(durationSeconds / 60.0));
    }

    /**
     * Deshace la finalización: la sesión vuelve a estar en curso. Devuelve lo que había antes para
     * restar la experiencia otorgada y avisar a los módulos dependientes.
     */
    public CompletionSnapshot unmark() {
        if (!isCompleted()) {
            throw new SessionNotCompletedException();
        }
        CompletionSnapshot snapshot = new CompletionSnapshot(completedAt, durationMinutes, rpe == null ? 1 : rpe,
                xpAwarded);
        this.completedAt = null;
        this.durationMinutes = 0;
        this.rpe = null;
        this.calories = null;
        this.xpAwarded = 0;
        return snapshot;
    }

    private void ensureInProgress() {
        if (isCompleted()) {
            throw new SessionAlreadyCompletedException();
        }
    }

    public boolean isCompleted() {
        return completedAt != null;
    }

    public boolean isOwnedBy(UUID uid) {
        return userId.equals(uid);
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public UUID routineId() { return routineId; }
    public UUID dayId() { return dayId; }
    public SessionType type() { return type; }
    public Instant startedAt() { return startedAt; }
    public Instant completedAt() { return completedAt; }
    public int durationMinutes() { return durationMinutes; }
    public Integer rpe() { return rpe; }
    public Double calories() { return calories; }
    public int xpAwarded() { return xpAwarded; }

    public List<SessionSet> sets() {
        return sets.stream()
                .sorted(Comparator.comparing((SessionSet s) -> String.valueOf(s.plannedExerciseId()))
                        .thenComparingInt(SessionSet::setNumber))
                .toList();
    }

    /** Estado de la sesión justo antes de desmarcarla. */
    public record CompletionSnapshot(Instant completedAt, int durationMinutes, int rpe, int xpAwarded) {
    }
}
