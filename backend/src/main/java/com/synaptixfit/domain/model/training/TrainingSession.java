package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.training.SessionAlreadyCompletedException;
import com.synaptixfit.domain.exception.training.SessionNotCompletedException;
import com.synaptixfit.domain.exception.training.SessionSetNotFoundException;
import com.synaptixfit.domain.exception.training.SessionUnmarkExpiredException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * Sesión de entrenamiento. Está en curso mientras {@code completedAt} es nulo; al finalizarla se
 * fijan duración, RPE, calorías y la experiencia otorgada, que se guarda para poder restar
 * exactamente esa cantidad si se desmarca o se elimina (anti-farmeo).
 *
 * <p>Una sesión abandonada (abierta más de {@link #STALE_AFTER}) nunca se borra sola: se termina con
 * lo registrado, y entonces cuenta en el día en que se hizo ({@link #completionInstant}), o se descarta.
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

    /**
     * Una sesión empezada hace más de esto y sin terminar se da por abandonada: no se reanuda ni
     * cuenta como «en curso» (nadie entrena 6 horas seguidas).
     */
    public static final Duration STALE_AFTER = Duration.ofHours(6);

    /** Duración máxima que se registra: lo que pase de aquí es una sesión que se dejó abierta. */
    public static final Duration MAX_DURATION = Duration.ofHours(4);

    /** En curso pero empezada hace más de {@link #STALE_AFTER}. */
    public boolean isStale(Instant now) {
        return completedAt == null && isStaleStart(startedAt, now);
    }

    /** Una sesión abierta que empezó en {@code startedAt} ya se da por abandonada en {@code now}. */
    public static boolean isStaleStart(Instant startedAt, Instant now) {
        return startedAt.plus(STALE_AFTER).isBefore(now);
    }

    /**
     * Duración que se guarda al terminar: la que manda el cliente, pero nunca más que el tiempo real
     * desde que empezó ni que {@link #MAX_DURATION} (una sesión olvidada abierta no suma 24 h de
     * carga ni de calorías).
     */
    public long boundedDurationSeconds(long requestedSeconds, Instant now) {
        long elapsed = Math.max(1, Duration.between(startedAt, now).toSeconds());
        return Math.max(1, Math.min(requestedSeconds, Math.min(elapsed, MAX_DURATION.toSeconds())));
    }

    /**
     * Cuándo se da por terminada: ahora, o si se abandonó, al acabar la duración registrada desde que
     * empezó. Así la carga, la XP y los retos caen en el día en que de verdad se entrenó.
     */
    public Instant completionInstant(long boundedDurationSeconds, Instant now) {
        return isStale(now) ? startedAt.plusSeconds(Math.max(1, boundedDurationSeconds)) : now;
    }

    /** Día local en que se terminó (null si sigue en curso). */
    public LocalDate completedOn(ZoneId zone) {
        return completedAt == null ? null : LocalDate.ofInstant(completedAt, zone);
    }

    /**
     * Sesión de un día de rutina entrenado sin la app (registro de una sesión pasada): ya terminada,
     * empezada {@code durationMinutes} antes de {@code completedAt}.
     */
    public static TrainingSession logged(UUID userId, UUID routineId, UUID dayId, Instant completedAt,
                                         int durationMinutes, int sessionRpe, double sessionCalories, int xp) {
        Guard.range(sessionRpe, "rpe", 1, 10);
        Guard.range(durationMinutes, "durationMinutes", 1, (int) MAX_DURATION.toMinutes());
        Instant started = completedAt.minus(Duration.ofMinutes(durationMinutes));
        return new TrainingSession(UUID.randomUUID(), userId, routineId, dayId, SessionType.ROUTINE, started,
                completedAt, durationMinutes, sessionRpe, Math.round(sessionCalories * 10) / 10.0, xp, List.of());
    }

    public static TrainingSession start(UUID userId, UUID routineId, UUID dayId, Instant now) {
        SessionType type = dayId == null ? SessionType.FREE : SessionType.ROUTINE;
        return new TrainingSession(UUID.randomUUID(), userId, routineId, dayId, type, now, null, 0, null, null, 0,
                List.of());
    }

    /** Registra (o sustituye) la serie {@code setNumber} del ejercicio planificado indicado. */
    public SessionSet recordSet(UUID plannedExerciseId, int setNumber, Integer repsDone, Double weightKg,
                                boolean completed, int failedReps) {
        return recordSet(plannedExerciseId, null, setNumber, repsDone, weightKg, completed, failedReps, null, null);
    }

    /**
     * Como {@link #recordSet(UUID, int, Integer, Double, boolean, int)}, con el ejercicio que se hizo y el
     * tiempo y la distancia de la serie.
     */
    public SessionSet recordSet(UUID plannedExerciseId, UUID exerciseId, int setNumber, Integer repsDone,
                                Double weightKg, boolean completed, int failedReps, Integer durationSeconds,
                                Integer distanceMeters) {
        ensureInProgress();
        sets.removeIf(s -> Objects.equals(s.plannedExerciseId(), plannedExerciseId) && s.setNumber() == setNumber);
        SessionSet set = new SessionSet(UUID.randomUUID(), plannedExerciseId, setNumber, repsDone, weightKg,
                completed, failedReps, durationSeconds, distanceMeters, exerciseId);
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
     * Corrige una sesión ya terminada (RPE y duración, que mandan sobre la carga física). La XP no
     * cambia: se otorgó al terminarla.
     */
    public void correct(int sessionRpe, int minutes, double sessionCalories) {
        if (!isCompleted()) {
            throw new SessionNotCompletedException();
        }
        this.rpe = Guard.range(sessionRpe, "rpe", 1, 10);
        this.durationMinutes = Guard.range(minutes, "durationMinutes", 1, (int) MAX_DURATION.toMinutes());
        this.calories = Math.round(sessionCalories * 10) / 10.0;
    }

    /** Se puede desmarcar: terminada ese mismo día ({@code today} en la zona {@code zone}). */
    public boolean canUnmark(LocalDate today, ZoneId zone) {
        return isCompleted() && completedOn(zone).equals(today);
    }

    /** Lo que había al terminarla, para retirar su XP y su carga al eliminarla. */
    public CompletionSnapshot snapshot() {
        if (!isCompleted()) {
            throw new SessionNotCompletedException();
        }
        return new CompletionSnapshot(completedAt, durationMinutes, rpe == null ? 1 : rpe, xpAwarded);
    }

    /**
     * Deshace la finalización: la sesión vuelve a estar en curso. Solo el mismo día en que se terminó
     * ({@code today} en la zona {@code zone}); una de otro día volvería abierta y ya abandonada, así que
     * se corrige o se elimina. Devuelve lo que había antes para restar la experiencia otorgada y avisar
     * a los módulos dependientes.
     */
    public CompletionSnapshot unmark(LocalDate today, ZoneId zone) {
        if (!isCompleted()) {
            throw new SessionNotCompletedException();
        }
        if (!canUnmark(today, zone)) {
            throw new SessionUnmarkExpiredException();
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
