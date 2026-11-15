package com.synaptixfit.domain.model.together;

import com.synaptixfit.domain.exception.together.FriendStreakLimitReachedException;
import com.synaptixfit.domain.exception.together.FriendStreakNudgeUnavailableException;
import com.synaptixfit.domain.exception.together.TogetherInvalidStateException;
import com.synaptixfit.domain.model.challenge.ActivityKind;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;

/**
 * Racha con un amigo (ADR 0044): los dos hacen «algo que cuenta» el mismo día (definición del servidor,
 * {@link #COUNTED_KINDS}). Se propone, se acepta y se termina; cada persona tiene como mucho
 * {@value #MAX_PER_PERSON} (propuestas o activas). Cuenta desde el día en que se aceptó ({@code since}); los días se
 * cuentan con {@link FriendStreakCount}. «Recordárselo» avisa al amigo como mucho una vez al día.
 */
public final class FriendStreak {

    public static final int MAX_PER_PERSON = 5;

    /**
     * Qué cuenta como «hecho» para la racha con un amigo: estudio (repaso, test o Pomodoro) o entreno hecho (la misma
     * definición que los retos, {@code CompletedWorkoutsSql}). Nunca el registro diario: es salud y no se comparte.
     */
    public static final Set<ActivityKind> COUNTED_KINDS =
            Set.of(ActivityKind.REVIEW, ActivityKind.TEST, ActivityKind.FOCUS, ActivityKind.WORKOUT);

    public enum Status { PENDING, ACTIVE }

    private final UUID id;
    private final UUID requesterId;
    private final UUID addresseeId;
    private Status status;
    private LocalDate since;
    private LocalDate lastNudgeOn;
    private final Instant createdAt;
    private Instant updatedAt;

    public FriendStreak(UUID id, UUID requesterId, UUID addresseeId, Status status, LocalDate since,
                        LocalDate lastNudgeOn, Instant createdAt, Instant updatedAt) {
        this.id = Guard.notNull(id, "id");
        this.requesterId = Guard.notNull(requesterId, "requesterId");
        this.addresseeId = Guard.notNull(addresseeId, "addresseeId");
        if (requesterId.equals(addresseeId)) {
            throw new TogetherInvalidStateException("A streak needs two people");
        }
        this.status = Guard.notNull(status, "status");
        this.since = since;
        this.lastNudgeOn = lastNudgeOn;
        this.createdAt = Guard.notNull(createdAt, "createdAt");
        this.updatedAt = updatedAt == null ? createdAt : updatedAt;
    }

    /** Comprueba que ninguna de las dos personas ha llegado al tope de rachas (propuestas o activas). */
    public static void ensureRoom(int requesterStreaks, int addresseeStreaks) {
        if (requesterStreaks >= MAX_PER_PERSON || addresseeStreaks >= MAX_PER_PERSON) {
            throw new FriendStreakLimitReachedException();
        }
    }

    /** La pareja en un orden fijo (para que solo haya una racha entre dos personas, la proponga quien la proponga). */
    public UUID lowerId() {
        return requesterId.compareTo(addresseeId) < 0 ? requesterId : addresseeId;
    }

    public UUID higherId() {
        return requesterId.compareTo(addresseeId) < 0 ? addresseeId : requesterId;
    }

    public static FriendStreak propose(UUID requesterId, UUID addresseeId, Instant now) {
        return new FriendStreak(UUID.randomUUID(), requesterId, addresseeId, Status.PENDING, null, null, now, now);
    }

    public boolean involves(UUID userId) {
        return requesterId.equals(userId) || addresseeId.equals(userId);
    }

    public UUID otherThan(UUID userId) {
        return requesterId.equals(userId) ? addresseeId : requesterId;
    }

    public boolean isActive() {
        return status == Status.ACTIVE;
    }

    /** Acepta quien la recibió; cuenta desde hoy. */
    public void accept(UUID userId, LocalDate today, Instant now) {
        if (status != Status.PENDING || !addresseeId.equals(userId)) {
            throw new TogetherInvalidStateException("Only the invited friend can accept a pending streak");
        }
        status = Status.ACTIVE;
        since = today;
        updatedAt = now;
    }

    /** Solo quien la recibió puede decir que no a una propuesta. */
    public void ensureDeclinableBy(UUID userId) {
        if (status != Status.PENDING || !addresseeId.equals(userId)) {
            throw new TogetherInvalidStateException("Only the invited friend can decline a pending streak");
        }
    }

    /** ¿Puede {@code userId} recordárselo hoy al amigo? Activa, sin aviso hoy, hecho por mí y no por él. */
    public boolean canNudge(LocalDate today, boolean meDone, boolean friendDone) {
        return isActive() && meDone && !friendDone && !today.equals(lastNudgeOn);
    }

    public void nudge(LocalDate today, boolean meDone, boolean friendDone, Instant now) {
        if (!canNudge(today, meDone, friendDone)) {
            throw new FriendStreakNudgeUnavailableException();
        }
        lastNudgeOn = today;
        updatedAt = now;
    }

    public UUID id() { return id; }
    public UUID requesterId() { return requesterId; }
    public UUID addresseeId() { return addresseeId; }
    public Status status() { return status; }
    public LocalDate since() { return since; }
    public LocalDate lastNudgeOn() { return lastNudgeOn; }
    public Instant createdAt() { return createdAt; }
    public Instant updatedAt() { return updatedAt; }
}
