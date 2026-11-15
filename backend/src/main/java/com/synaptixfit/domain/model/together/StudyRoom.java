package com.synaptixfit.domain.model.together;

import com.synaptixfit.domain.exception.together.TogetherInvalidStateException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Sala de «Estudiamos juntos» (ADR 0045): quien crea y de 1 a {@value #MAX_FRIENDS} amigos mutuos comparten un
 * temporizador de {@value #MIN_ROUNDS} a {@value #MAX_ROUNDS} rondas. El tiempo no se guarda en ningún móvil: todo
 * sale de la hora de inicio que guarda el servidor, así cada uno pinta la misma cuenta atrás.
 *
 * <p>Nadie gobierna la sala: cualquiera que esté dentro cambia sus minutos ({@link StudyRoomTimes}) mientras espera
 * y la empieza; una vez empezada, va sola, sin pausas. Si quien la creó se va, sigue igual para los demás. Caduca sola: al terminar la última ronda o, si nadie la empieza,
 * {@link #WAITING_LIMIT} después de crearla.
 *
 * <p>Cada ronda terminada cuenta como un Pomodoro normal para cada persona que estaba dentro al acabar
 * ({@link #creditsDue}), con los minutos que estuvo y la asignatura que eligió (que solo ve ella).
 */
public final class StudyRoom {

    public static final int MAX_FRIENDS = 4;
    public static final int MIN_ROUNDS = 1;
    public static final int MAX_ROUNDS = 4;
    /** Una sala que nadie empieza caduca a las 4 h: es el «4 h sin nadie» del plan. */
    public static final Duration WAITING_LIMIT = Duration.ofHours(4);
    /** Una reacción se enseña durante 2 minutos: basta para verla con la consulta periódica y no se acumula. */
    public static final Duration REACTION_SHOWN = Duration.ofMinutes(2);

    /** En qué punto está la sala: esperando, concentración, descanso, terminada o caducada sin empezar. */
    public enum Phase { WAITING, FOCUS, BREAK, FINISHED, EXPIRED }

    /**
     * La sala en un instante.
     *
     * @param round  ronda en curso (en el descanso, la que acaba de terminar); 0 si no ha empezado
     * @param endsAt cuándo termina la fase (en la espera, cuándo caduca); nulo si ya terminó
     */
    public record Moment(Phase phase, int round, Instant endsAt) {

        public boolean over() {
            return phase == Phase.FINISHED || phase == Phase.EXPIRED;
        }
    }

    /** Un Pomodoro que hay que apuntar a una persona por una ronda terminada. */
    public record Credit(UUID userId, int round, int minutes, Instant endedAt, UUID subjectId) {
    }

    /** Última reacción de una persona y cuándo la puso. */
    public record MemberReaction(StudyRoomReaction reaction, Instant at) {
    }

    private final UUID id;
    private final UUID creatorId;
    private StudyRoomTimes times;
    private final int rounds;
    private final Instant createdAt;
    private Instant startedAt;
    private int creditedRounds;
    private final TogetherMembers members;
    private final Map<UUID, UUID> subjects;
    private final Map<UUID, MemberReaction> reactions;
    /** Cuándo entró cada persona la última vez (al crear o al unirse); sigue guardado después de salir. */
    private final Map<UUID, Instant> enteredAt;

    @SuppressWarnings("java:S107")
    public StudyRoom(UUID id, UUID creatorId, StudyRoomTimes times, int rounds, Instant createdAt, Instant startedAt,
                     int creditedRounds, TogetherMembers members, Map<UUID, UUID> subjects,
                     Map<UUID, MemberReaction> reactions) {
        this(id, creatorId, times, rounds, createdAt, startedAt, creditedRounds, members, subjects, reactions,
                Map.of());
    }

    /** @param enteredAt cuándo entró cada persona; sin dato, se toma el último cambio de quien está dentro */
    @SuppressWarnings("java:S107")
    public StudyRoom(UUID id, UUID creatorId, StudyRoomTimes times, int rounds, Instant createdAt, Instant startedAt,
                     int creditedRounds, TogetherMembers members, Map<UUID, UUID> subjects,
                     Map<UUID, MemberReaction> reactions, Map<UUID, Instant> enteredAt) {
        this.id = Guard.notNull(id, "id");
        this.creatorId = Guard.notNull(creatorId, "creatorId");
        this.times = Guard.notNull(times, "times");
        this.rounds = Guard.range(rounds, "rounds", MIN_ROUNDS, MAX_ROUNDS);
        this.createdAt = Guard.notNull(createdAt, "createdAt");
        this.startedAt = startedAt;
        this.creditedRounds = Math.clamp(creditedRounds, 0, rounds);
        this.members = Guard.notNull(members, "members");
        this.subjects = new HashMap<>(subjects == null ? Map.of() : subjects);
        this.reactions = new HashMap<>(reactions == null ? Map.of() : reactions);
        this.enteredAt = new HashMap<>(enteredAt == null ? Map.of() : enteredAt);
    }

    /** Crea la sala con quien la crea dentro (con su asignatura, si eligió una) y los amigos invitados. */
    public static StudyRoom create(UUID creatorId, Set<UUID> friendIds, StudyRoomTimes times, int rounds,
                                   UUID subjectId, Instant now) {
        Map<UUID, UUID> subjects = new HashMap<>();
        if (subjectId != null) {
            subjects.put(creatorId, subjectId);
        }
        return new StudyRoom(UUID.randomUUID(), creatorId, times, rounds, now, null, 0,
                TogetherMembers.create(creatorId, friendIds == null ? Set.of() : friendIds, 1, MAX_FRIENDS, now),
                subjects, Map.of(), Map.of(creatorId, now));
    }

    // ------------------------------------------------------------------ tiempo

    public Moment momentAt(Instant now) {
        if (startedAt == null) {
            Instant expires = createdAt.plus(WAITING_LIMIT);
            return now.isBefore(expires) ? new Moment(Phase.WAITING, 0, expires) : new Moment(Phase.EXPIRED, 0, null);
        }
        for (int round = 1; round <= rounds; round++) {
            Instant focusEnd = roundEndsAt(round);
            if (now.isBefore(focusEnd)) {
                return new Moment(Phase.FOCUS, round, focusEnd);
            }
            Instant breakEnd = focusEnd.plus(breakDuration());
            if (round < rounds && now.isBefore(breakEnd)) {
                return new Moment(Phase.BREAK, round, breakEnd);
            }
        }
        return new Moment(Phase.FINISHED, rounds, null);
    }

    public boolean isOver(Instant now) {
        return momentAt(now).over();
    }

    /** Cuándo termina la última ronda (nulo si no ha empezado). */
    public Instant endsAt() {
        return startedAt == null ? null : roundEndsAt(rounds);
    }

    Instant roundStartsAt(int round) {
        return startedAt.plus(focusDuration().plus(breakDuration()).multipliedBy(round - 1L));
    }

    Instant roundEndsAt(int round) {
        return roundStartsAt(round).plus(focusDuration());
    }

    private Duration focusDuration() {
        return Duration.ofMinutes(times.focusMinutes());
    }

    private Duration breakDuration() {
        return Duration.ofMinutes(times.breakMinutes());
    }

    /** Rondas cuya concentración ya ha terminado. */
    int finishedRounds(Instant now) {
        if (startedAt == null) {
            return 0;
        }
        int done = 0;
        for (int round = 1; round <= rounds && !roundEndsAt(round).isAfter(now); round++) {
            done = round;
        }
        return done;
    }

    // ------------------------------------------------------------------ personas

    public boolean canView(UUID userId) {
        return members.canView(userId);
    }

    /** Cualquiera que esté dentro empieza la sala, una sola vez: después va sola. */
    public void start(UUID userId, Instant now) {
        if (!members.find(userId).map(TogetherMember::joined).orElse(false)) {
            throw new TogetherInvalidStateException("Join before starting");
        }
        if (momentAt(now).phase() != Phase.WAITING) {
            throw new TogetherInvalidStateException("The room is not waiting");
        }
        startedAt = now;
    }

    /**
     * Cambia los minutos de la ronda. Cualquiera que esté dentro puede hacerlo, pero solo antes de empezar: con el
     * temporizador en marcha cambiaría la cuenta atrás de todos a mitad de ronda.
     */
    public void changeTimes(UUID userId, StudyRoomTimes newTimes, Instant now) {
        Guard.notNull(newTimes, "times");
        if (!members.find(userId).map(TogetherMember::joined).orElse(false)) {
            throw new TogetherInvalidStateException("Join before changing the times");
        }
        if (momentAt(now).phase() != Phase.WAITING) {
            throw new TogetherInvalidStateException("The room is not waiting");
        }
        times = newTimes;
    }

    /** Acepta la invitación o vuelve tras salir («Deshacer»), mientras la sala no haya terminado. */
    public void join(UUID userId, Instant now) {
        ensureOpen(now);
        members.join(userId, now);
        enteredAt.put(userId, now);
    }

    public void decline(UUID userId, Instant now) {
        members.decline(userId, now);
    }

    /** Sale; los demás siguen. Idempotente. */
    public boolean leave(UUID userId, Instant now) {
        boolean changed = members.leave(userId, now);
        if (changed) {
            reactions.remove(userId);
        }
        return changed;
    }

    /** Elige la asignatura con la que le cuenta cada ronda (nula: ninguna). Solo la ve esa persona. */
    public void chooseSubject(UUID userId, UUID subjectId) {
        if (!canView(userId)) {
            throw new TogetherInvalidStateException("Not in the room");
        }
        if (subjectId == null) {
            subjects.remove(userId);
        } else {
            subjects.put(userId, subjectId);
        }
    }

    /** Pone (o cambia) la reacción de una persona de dentro. */
    public void react(UUID userId, StudyRoomReaction reaction, Instant now) {
        Guard.notNull(reaction, "reaction");
        ensureOpen(now);
        if (!members.find(userId).map(TogetherMember::joined).orElse(false)) {
            throw new TogetherInvalidStateException("Join before reacting");
        }
        reactions.put(userId, new MemberReaction(reaction, now));
    }

    /** La reacción de una persona si la puso hace menos de {@link #REACTION_SHOWN}. */
    public Optional<StudyRoomReaction> reactionShown(UUID userId, Instant now) {
        return Optional.ofNullable(reactions.get(userId))
                .filter(r -> r.at().plus(REACTION_SHOWN).isAfter(now))
                .map(MemberReaction::reaction);
    }

    private void ensureOpen(Instant now) {
        if (isOver(now)) {
            throw new TogetherInvalidStateException("The room is over");
        }
    }

    // ------------------------------------------------------------------ rondas que cuentan

    /**
     * Pomodoros que faltan por apuntar: por cada ronda terminada y aún sin contar, uno a cada persona que estaba
     * dentro al acabar, con los minutos que estuvo en esa ronda (desde que entró, si llegó tarde). Quien salió antes
     * del final no suma esa ronda; quien salió después sí, aunque se cuente más tarde: así salir no tiene que apuntar
     * nada y el programador lo hace al minuto. Antes de volver a entrar el servicio cuenta lo pendiente, porque entrar
     * cambia la hora de entrada.
     */
    public List<Credit> creditsDue(Instant now) {
        List<Credit> credits = new ArrayList<>();
        for (int round = creditedRounds + 1; round <= finishedRounds(now); round++) {
            Instant start = roundStartsAt(round);
            Instant end = roundEndsAt(round);
            for (TogetherMember m : members.all()) {
                Instant entered = enteredAt.getOrDefault(m.userId(), m.joined() ? m.updatedAt() : null);
                if (entered == null || !entered.isBefore(end) || !insideAt(m, end)) {
                    continue;
                }
                Instant from = entered.isAfter(start) ? entered : start;
                long minutes = Duration.between(from, end).toMinutes();
                if (minutes >= 1) {
                    credits.add(new Credit(m.userId(), round, (int) minutes, end, subjects.get(m.userId())));
                }
            }
        }
        return credits;
    }

    /** ¿Seguía dentro en {@code at}? Dentro ahora, o salió en ese momento o después. */
    private static boolean insideAt(TogetherMember m, Instant at) {
        return m.joined() || (m.status() == MemberStatus.LEFT && !m.updatedAt().isBefore(at));
    }

    /** Rondas que ya se han contado hasta {@code now} (lo que quedará en {@link #creditedRounds()}). */
    public int roundsToCredit(Instant now) {
        return Math.max(creditedRounds, finishedRounds(now));
    }

    public void markCredited(int upTo) {
        creditedRounds = Math.clamp(Math.max(creditedRounds, upTo), 0, rounds);
    }

    // ------------------------------------------------------------------ lectura

    public UUID id() { return id; }
    public UUID creatorId() { return creatorId; }
    public StudyRoomTimes times() { return times; }
    public int rounds() { return rounds; }
    public Instant createdAt() { return createdAt; }
    public Instant startedAt() { return startedAt; }
    public int creditedRounds() { return creditedRounds; }
    public TogetherMembers members() { return members; }
    public Optional<UUID> subjectOf(UUID userId) { return Optional.ofNullable(subjects.get(userId)); }
    public Map<UUID, UUID> subjects() { return Map.copyOf(subjects); }
    public Map<UUID, MemberReaction> reactions() { return Map.copyOf(reactions); }
    public Map<UUID, Instant> enteredAt() { return Map.copyOf(enteredAt); }
}
