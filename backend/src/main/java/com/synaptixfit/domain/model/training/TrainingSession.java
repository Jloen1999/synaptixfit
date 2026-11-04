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
 *
 * <p>Pausas (ADR 0030): mientras {@code pausedAt} no es nulo la sesión está en pausa; al reanudar, ese
 * tiempo se suma a {@code pausedSeconds}. Las pausas no cuentan como entrenamiento: la duración que se
 * guarda (y con ella la carga física y las calorías) es el tiempo activo ({@link #activeSeconds}).
 *
 * <p>Series de calentamiento (ADR 0031): van en una lista aparte ({@link #warmupSets}) con su propia
 * numeración. {@link #sets} solo devuelve las de trabajo, que son las que cuentan para el volumen, los
 * récords, la propuesta de peso y el progreso del día.
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
    private final List<SessionSet> warmupSets;
    private Instant pausedAt;
    private long pausedSeconds;

    public TrainingSession(UUID id, UUID userId, UUID routineId, UUID dayId, SessionType type, Instant startedAt,
                           Instant completedAt, int durationMinutes, Integer rpe, Double calories, int xpAwarded,
                           List<SessionSet> sets) {
        this(id, userId, routineId, dayId, type, startedAt, completedAt, durationMinutes, rpe, calories, xpAwarded,
                sets, null, 0);
    }

    public TrainingSession(UUID id, UUID userId, UUID routineId, UUID dayId, SessionType type, Instant startedAt,
                           Instant completedAt, int durationMinutes, Integer rpe, Double calories, int xpAwarded,
                           List<SessionSet> sets, Instant pausedAt, long pausedSeconds) {
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
        List<SessionSet> all = sets == null ? List.of() : sets;
        this.sets = new ArrayList<>(all.stream().filter(s -> !s.warmup()).toList());
        this.warmupSets = new ArrayList<>(all.stream().filter(SessionSet::warmup).toList());
        this.pausedAt = completedAt == null ? pausedAt : null;
        this.pausedSeconds = Math.max(0, pausedSeconds);
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
     * Duración que se guarda al terminar: la que manda el cliente, pero nunca más que el tiempo activo
     * desde que empezó (sin pausas) ni que {@link #MAX_DURATION} (una sesión olvidada abierta no suma
     * 24 h de carga ni de calorías).
     */
    public long boundedDurationSeconds(long requestedSeconds, Instant now) {
        long active = Math.max(1, activeSeconds(now));
        return Math.max(1, Math.min(requestedSeconds, Math.min(active, MAX_DURATION.toSeconds())));
    }

    /** Segundos entrenados hasta {@code now}: desde que empezó, menos las pausas (también la que siga abierta). */
    public long activeSeconds(Instant now) {
        long elapsed = Duration.between(startedAt, now).toSeconds();
        return Math.max(0, elapsed - pausedSecondsAt(now));
    }

    /** Segundos en pausa hasta {@code now}, incluida la pausa en curso. */
    public long pausedSecondsAt(Instant now) {
        long open = pausedAt == null ? 0 : Math.max(0, Duration.between(pausedAt, now).toSeconds());
        return pausedSeconds + open;
    }

    /**
     * Pausa la sesión (una llamada, una máquina ocupada…): el tiempo deja de contar hasta reanudarla.
     * Pausar una sesión ya pausada no hace nada, para que un doble toque o un reintento no falle.
     */
    public void pause(Instant now) {
        ensureInProgress();
        if (pausedAt == null) {
            pausedAt = now.isBefore(startedAt) ? startedAt : now;
        }
    }

    /** Reanuda la sesión: el tiempo en pausa se acumula. Reanudar una sesión que no está en pausa no hace nada. */
    public void resume(Instant now) {
        resume(now, now);
    }

    /**
     * Reanuda la sesión como si se hubiera hecho en {@code resumedAt}: el móvil reanuda al momento y,
     * sin conexión, avisa más tarde. Se acota entre el inicio de la pausa y {@code now}, así que nunca
     * descuenta menos pausa de la que hubo hasta ese toque ni inventa tiempo futuro.
     */
    public void resume(Instant resumedAt, Instant now) {
        ensureInProgress();
        if (pausedAt == null) {
            return;
        }
        Instant at = resumedAt == null || resumedAt.isAfter(now) ? now : resumedAt;
        closePause(at.isBefore(pausedAt) ? pausedAt : at);
    }

    private void closePause(Instant now) {
        if (pausedAt != null) {
            pausedSeconds += Math.max(0, Duration.between(pausedAt, now).toSeconds());
            pausedAt = null;
        }
    }

    public boolean isPaused() {
        return pausedAt != null;
    }

    /**
     * Cuándo se da por terminada: ahora, o si se abandonó, al acabar la duración registrada desde que
     * empezó. Así la carga, la XP y los retos caen en el día en que de verdad se entrenó.
     */
    public Instant completionInstant(long boundedDurationSeconds, Instant now) {
        if (!isStale(now)) {
            return now;
        }
        // Las pausas ya cerradas también pasaron ese día; una pausa que quedó abierta no (se dejó así).
        Instant end = startedAt.plusSeconds(Math.max(1, boundedDurationSeconds) + pausedSeconds);
        return end.isAfter(now) ? now : end;
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
        return recordSet(plannedExerciseId, exerciseId, setNumber, repsDone, weightKg, completed, failedReps,
                durationSeconds, distanceMeters, null);
    }

    /** Como el anterior, con los segundos que marcó el cronómetro de la serie (null si no se usó). */
    public SessionSet recordSet(UUID plannedExerciseId, UUID exerciseId, int setNumber, Integer repsDone,
                                Double weightKg, boolean completed, int failedReps, Integer durationSeconds,
                                Integer distanceMeters, Integer activeSeconds) {
        return recordSet(plannedExerciseId, exerciseId, setNumber, repsDone, weightKg, completed, failedReps,
                durationSeconds, distanceMeters, activeSeconds, false);
    }

    /** Como el anterior, indicando si la serie se hizo hasta no poder más ({@code toFailure}). */
    public SessionSet recordSet(UUID plannedExerciseId, UUID exerciseId, int setNumber, Integer repsDone,
                                Double weightKg, boolean completed, int failedReps, Integer durationSeconds,
                                Integer distanceMeters, Integer activeSeconds, boolean toFailure) {
        ensureInProgress();
        sets.removeIf(s -> Objects.equals(s.plannedExerciseId(), plannedExerciseId) && s.setNumber() == setNumber);
        SessionSet set = new SessionSet(UUID.randomUUID(), plannedExerciseId, setNumber, repsDone, weightKg,
                completed, failedReps, durationSeconds, distanceMeters, exerciseId, activeSeconds, false, toFailure);
        sets.add(set);
        return set;
    }

    /**
     * Registra (o sustituye) la serie de calentamiento número {@code setNumber} de un ejercicio. Tiene su propia
     * numeración: «Calentamiento 1» no pisa la «Serie 1» de trabajo. Siempre cuenta como completada.
     */
    public SessionSet recordWarmupSet(UUID plannedExerciseId, UUID exerciseId, int setNumber, Integer repsDone,
                                      Double weightKg, Integer durationSeconds, Integer distanceMeters,
                                      Integer activeSeconds) {
        ensureInProgress();
        warmupSets.removeIf(s -> Objects.equals(s.plannedExerciseId(), plannedExerciseId)
                && s.setNumber() == setNumber);
        SessionSet set = new SessionSet(UUID.randomUUID(), plannedExerciseId, setNumber, repsDone, weightKg,
                true, 0, durationSeconds, distanceMeters, exerciseId, activeSeconds, true, false);
        warmupSets.add(set);
        return set;
    }

    /** Quita una serie, de trabajo o de calentamiento. */
    public void removeSet(UUID setId) {
        ensureInProgress();
        if (!sets.removeIf(s -> s.id().equals(setId)) && !warmupSets.removeIf(s -> s.id().equals(setId))) {
            throw new SessionSetNotFoundException(setId);
        }
    }

    /** Finaliza la sesión. La duración se redondea a minutos (mínimo 1). */
    public void complete(long durationSeconds, int sessionRpe, double sessionCalories, int xp, Instant now) {
        ensureInProgress();
        Guard.range(sessionRpe, "rpe", 1, 10);
        Guard.range((double) durationSeconds, "durationSeconds", 1, 86_400);
        closePause(now.isBefore(startedAt) ? startedAt : now);
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
        this.pausedAt = null;
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
    public Instant pausedAt() { return pausedAt; }
    public long pausedSeconds() { return pausedSeconds; }

    public List<SessionSet> sets() {
        return sets.stream()
                .sorted(Comparator.comparing((SessionSet s) -> String.valueOf(s.plannedExerciseId()))
                        .thenComparingInt(SessionSet::setNumber))
                .toList();
    }

    /** Series de calentamiento (no cuentan como trabajo), en el mismo orden que {@link #sets}. */
    public List<SessionSet> warmupSets() {
        return warmupSets.stream()
                .sorted(Comparator.comparing((SessionSet s) -> String.valueOf(s.plannedExerciseId()))
                        .thenComparingInt(SessionSet::setNumber))
                .toList();
    }

    /** Todas las series (trabajo y calentamiento), para guardarlas. */
    public List<SessionSet> allSets() {
        List<SessionSet> all = new ArrayList<>(sets());
        all.addAll(warmupSets());
        return all;
    }

    /** Estado de la sesión justo antes de desmarcarla. */
    public record CompletionSnapshot(Instant completedAt, int durationMinutes, int rpe, int xpAwarded) {
    }
}
