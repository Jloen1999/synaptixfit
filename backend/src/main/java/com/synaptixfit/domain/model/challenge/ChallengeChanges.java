package com.synaptixfit.domain.model.challenge;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.UUID;

/**
 * Efectos de una operación sobre un reto que la aplicación debe propagar: experiencia neta (positiva o
 * negativa), tareas desbloqueadas y transición del reto a completado. Los vínculos con entregas y
 * exámenes ya no se propagan: la entrega es la fuente de verdad y el reto solo la sigue (ADR 0028).
 */
public final class ChallengeChanges {

    private int xpDelta;
    private final LinkedHashSet<UUID> unlockedMilestones = new LinkedHashSet<>();
    private boolean challengeCompleted;
    private boolean challengeUncompleted;

    void addXp(int amount) {
        xpDelta += amount;
    }

    void revokeXp(int amount) {
        xpDelta -= amount;
    }

    void unlocked(UUID milestoneId) {
        unlockedMilestones.add(milestoneId);
    }

    void completedTransition(boolean nowCompleted) {
        if (nowCompleted) {
            challengeCompleted = true;
            challengeUncompleted = false;
        } else {
            challengeUncompleted = true;
            challengeCompleted = false;
        }
    }

    /** Une los efectos de otra operación sobre el mismo reto. */
    public ChallengeChanges merge(ChallengeChanges other) {
        xpDelta += other.xpDelta;
        unlockedMilestones.addAll(other.unlockedMilestones);
        if (other.challengeCompleted || other.challengeUncompleted) {
            completedTransition(other.challengeCompleted);
        }
        return this;
    }

    /** ¿Ha cambiado algo que haya que guardar o propagar? */
    public boolean isEmpty() {
        return xpDelta == 0 && unlockedMilestones.isEmpty() && !challengeCompleted && !challengeUncompleted;
    }

    /** Experiencia neta a sumar (positiva) o restar (negativa). */
    public int xpDelta() {
        return xpDelta;
    }

    public List<UUID> unlockedMilestoneIds() {
        return List.copyOf(unlockedMilestones);
    }

    /** El reto ha pasado a completado en esta operación. */
    public boolean challengeCompleted() {
        return challengeCompleted;
    }

    /** El reto ha dejado de estar completado en esta operación. */
    public boolean challengeUncompleted() {
        return challengeUncompleted;
    }
}
