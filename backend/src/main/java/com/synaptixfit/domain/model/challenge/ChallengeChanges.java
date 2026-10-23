package com.synaptixfit.domain.model.challenge;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Efectos de una operación sobre un reto que la aplicación debe propagar: experiencia neta
 * (positiva o negativa), vínculos con exámenes/entregas cuyo estado ha cambiado, tareas
 * desbloqueadas y transición del reto a completado.
 */
public final class ChallengeChanges {

    private int xpDelta;
    private final Map<UUID, LinkCompletionChange> linkChanges = new LinkedHashMap<>();
    private final LinkedHashSet<UUID> unlockedMilestones = new LinkedHashSet<>();
    private boolean challengeCompleted;
    private boolean challengeUncompleted;

    void addXp(int amount) {
        xpDelta += amount;
    }

    void revokeXp(int amount) {
        xpDelta -= amount;
    }

    void linkChanged(ChallengeLink link, boolean completed) {
        if (link != null && link.type().isDeadline()) {
            linkChanges.put(link.entityId(), new LinkCompletionChange(link, completed));
        }
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
        linkChanges.putAll(other.linkChanges);
        unlockedMilestones.addAll(other.unlockedMilestones);
        if (other.challengeCompleted || other.challengeUncompleted) {
            completedTransition(other.challengeCompleted);
        }
        return this;
    }

    /** Experiencia neta a sumar (positiva) o restar (negativa). */
    public int xpDelta() {
        return xpDelta;
    }

    /** Vínculos con exámenes/entregas cuyo estado ha cambiado (uno por entidad, el último estado). */
    public List<LinkCompletionChange> linkChanges() {
        return new ArrayList<>(linkChanges.values());
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
