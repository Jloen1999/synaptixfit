package com.synaptixfit.domain.model.together;

import com.synaptixfit.domain.exception.together.TogetherInvalidStateException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.SessionSet;
import java.time.Instant;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;

/**
 * «Entrenamos juntos» (ADR 0044): quien invita elige un día de su rutina y de 1 a {@value #MAX_FRIENDS} amigos
 * mutuos para hacerlo hoy, cada uno en su móvil con su sesión normal. Solo vale el día en que se crea; después queda
 * como recuerdo (la tarjeta conjunta). Guarda la sesión de cada persona para enseñar, por ejercicio, quién lo tiene
 * hecho; nunca pesos, repeticiones ni esfuerzo.
 */
public final class WorkoutTogether {

    public static final int MAX_FRIENDS = 4;

    /** Cómo va cada persona: sin empezar, entrenando o ya ha terminado. */
    public enum MemberState { NOT_STARTED, TRAINING, FINISHED }

    private final UUID id;
    private final UUID hostId;
    private final UUID routineId;
    private final UUID dayId;
    private final LocalDate date;
    private final Instant createdAt;
    private final TogetherMembers members;
    private final Map<UUID, UUID> sessions;

    public WorkoutTogether(UUID id, UUID hostId, UUID routineId, UUID dayId, LocalDate date, Instant createdAt,
                           TogetherMembers members, Map<UUID, UUID> sessions) {
        this.id = Guard.notNull(id, "id");
        this.hostId = Guard.notNull(hostId, "hostId");
        this.routineId = Guard.notNull(routineId, "routineId");
        this.dayId = Guard.notNull(dayId, "dayId");
        this.date = Guard.notNull(date, "date");
        this.createdAt = Guard.notNull(createdAt, "createdAt");
        this.members = Guard.notNull(members, "members");
        this.sessions = new HashMap<>(sessions == null ? Map.of() : sessions);
    }

    public static WorkoutTogether create(UUID hostId, UUID routineId, UUID dayId, Set<UUID> friendIds,
                                         LocalDate today, Instant now) {
        return new WorkoutTogether(UUID.randomUUID(), hostId, routineId, dayId, today, now,
                TogetherMembers.create(hostId, friendIds, 1, MAX_FRIENDS, now), Map.of());
    }

    public boolean isFor(LocalDate today) {
        return date.equals(today);
    }

    public boolean canView(UUID userId) {
        return members.canView(userId);
    }

    public void join(UUID userId, LocalDate today, Instant now) {
        ensureToday(today);
        members.join(userId, now);
    }

    public void decline(UUID userId, Instant now) {
        members.decline(userId, now);
    }

    public boolean leave(UUID userId, Instant now) {
        return members.leave(userId, now);
    }

    /** Guarda la sesión con la que entrena {@code userId} (tiene que estar dentro y ser hoy). */
    public void attachSession(UUID userId, UUID sessionId, LocalDate today) {
        ensureToday(today);
        if (!members.find(userId).map(TogetherMember::joined).orElse(false)) {
            throw new TogetherInvalidStateException("Join before starting");
        }
        sessions.put(userId, Guard.notNull(sessionId, "sessionId"));
    }

    public Optional<UUID> sessionOf(UUID userId) {
        return Optional.ofNullable(sessions.get(userId));
    }

    private void ensureToday(LocalDate today) {
        if (!isFor(today)) {
            throw new TogetherInvalidStateException("Workout together was for " + date);
        }
    }

    /**
     * Huecos del día (por su posición) que una persona tiene hechos: los que llevan al menos tantas series de
     * trabajo como tiene planificadas. Se cuenta por hueco y no por ejercicio para que «Cambiar solo hoy» siga
     * contando; las copias de la rutina conservan el orden de los huecos.
     */
    public static Set<Integer> doneSlots(List<PlannedExercise> day, List<SessionSet> workSets) {
        Set<Integer> done = new TreeSet<>();
        for (int i = 0; i < day.size(); i++) {
            PlannedExercise planned = day.get(i);
            long sets = workSets.stream().filter(s -> !s.warmup() && planned.id().equals(s.plannedExerciseId()))
                    .count();
            if (sets >= Math.max(1, planned.parameters().sets())) {
                done.add(i);
            }
        }
        return done;
    }

    public UUID id() { return id; }
    public UUID hostId() { return hostId; }
    public UUID routineId() { return routineId; }
    public UUID dayId() { return dayId; }
    public LocalDate date() { return date; }
    public Instant createdAt() { return createdAt; }
    public TogetherMembers members() { return members; }
    public Map<UUID, UUID> sessions() { return Map.copyOf(sessions); }
}
