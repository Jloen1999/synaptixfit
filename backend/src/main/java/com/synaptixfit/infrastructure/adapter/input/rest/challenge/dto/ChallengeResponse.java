package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeStatus;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.challenge.Milestone;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Reto con sus tareas. {@code owned} indica si es del usuario; {@code ownerName} solo se rellena
 * en retos ajenos. {@code xpReward} es el XP que da completarlo (sin tareas) y {@code xpAwarded} el
 * XP otorgado por su estado actual. {@code sessionTarget} (null si no aplica) y
 * {@code sessionsCompleted}: objetivo y recuento de entrenamientos de un reto de fitness por sesiones;
 * {@code tracksTrainingSessions} dice si el reto avanza con ellos ({@code Challenge.tracksTrainingSessions()}),
 * para que el cliente no repita la regla.
 */
public record ChallengeResponse(UUID id, UUID ownerId, boolean owned, String ownerName, String title,
                                ChallengeType type, String goal, Visibility visibility, Difficulty difficulty,
                                int xpReward, int xpAwarded, boolean completed, ChallengeStatus status, double progress,
                                Instant startAt, Instant endAt, UUID subjectId, LinkType linkedEntityType,
                                UUID linkedEntityId, int currentStreak, int bestStreak, LocalDate lastActiveDay,
                                boolean hasDependencies, int milestoneCount, int completedMilestoneCount,
                                List<MilestoneResponse> milestones, UUID originId, UUID originOwnerId,
                                String originOwnerName, Integer sessionTarget, int sessionsCompleted,
                                boolean tracksTrainingSessions, Instant createdAt, Instant updatedAt) {

    public static ChallengeResponse from(Challenge c, boolean owned, String ownerName, Instant now) {
        List<Milestone> ms = c.milestones();
        return new ChallengeResponse(c.id(), c.ownerId(), owned, ownerName, c.title(), c.type(), c.goal(),
                c.visibility(), c.difficulty(), ms.isEmpty() ? c.difficulty().xp() : 0, c.xpAwarded(), c.completed(),
                c.status(now), c.progress(), c.startAt(), c.endAt(), c.subjectId(),
                c.link() == null ? null : c.link().type(), c.link() == null ? null : c.link().entityId(),
                c.currentStreak(), c.bestStreak(), c.lastActiveDay(), c.hasDependencies(), ms.size(),
                (int) ms.stream().filter(Milestone::completed).count(),
                ms.stream().map(MilestoneResponse::from).toList(), c.originId(), c.originOwnerId(),
                c.originOwnerName(), c.sessionTarget(), c.sessionsCompleted(), c.tracksTrainingSessions(), c.createdAt(),
                c.updatedAt());
    }

    public static ChallengeResponse own(Challenge c, Instant now) {
        return from(c, true, null, now);
    }
}
