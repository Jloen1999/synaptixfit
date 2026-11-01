package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeStatus;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.challenge.LinkedDeadline;
import com.synaptixfit.domain.model.challenge.Milestone;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Reto con sus tareas. {@code owned} indica si es del usuario; {@code ownerName} solo se rellena en retos
 * ajenos. {@code status} puede ser {@code UPCOMING} (aún no empieza); {@code open} dice si ahora se puede
 * actuar a mano (entre inicio y fin, ADR 0028). {@code xpReward} es el XP total que
 * puede dar, con el tope ya aplicado, y {@code xpAwarded} el otorgado por su estado actual.
 * {@code currentStreak} es la racha vigente hoy (0 si se rompió). {@code completedByLink}: sin tareas, lo
 * completa su entrega vinculada ({@code linkTitle}, {@code linkDueAt}, {@code linkCompleted}; solo en retos
 * propios). {@code sessionTarget}/{@code sessionsCompleted}/{@code tracksTrainingSessions}: reto de fitness
 * por sesiones. Todas son reglas del servidor que el cliente no repite.
 */
public record ChallengeResponse(UUID id, UUID ownerId, boolean owned, String ownerName, String title,
                                ChallengeType type, String goal, Visibility visibility, Difficulty difficulty,
                                int xpReward, int xpAwarded, boolean completed, ChallengeStatus status, double progress,
                                boolean open, Instant startAt, Instant endAt, UUID subjectId,
                                LinkType linkedEntityType,
                                UUID linkedEntityId, String linkTitle, Instant linkDueAt, Boolean linkCompleted,
                                boolean completedByLink, int currentStreak, int bestStreak, LocalDate lastActiveDay,
                                boolean hasDependencies, int milestoneCount, int completedMilestoneCount,
                                List<MilestoneResponse> milestones, UUID originId, UUID originOwnerId,
                                String originOwnerName, Integer sessionTarget, int sessionsCompleted,
                                boolean tracksTrainingSessions, Instant createdAt, Instant updatedAt) {

    public static ChallengeResponse from(Challenge c, boolean owned, String ownerName, ResponseTime time) {
        List<Milestone> ms = c.milestones();
        Map<UUID, Integer> xp = c.milestoneXp();
        // La foto de la entrega vinculada es del autor: no se muestra en retos ajenos.
        LinkedDeadline deadline = owned ? c.linkedDeadline(c.link()).orElse(null) : null;
        return new ChallengeResponse(c.id(), c.ownerId(), owned, ownerName, c.title(), c.type(), c.goal(),
                c.visibility(), c.difficulty(), c.xpReward(), c.xpAwarded(), c.completed(),
                c.status(time.now()), c.progress(), c.isOpenAt(time.now()), c.startAt(), c.endAt(), c.subjectId(),
                c.link() == null ? null : c.link().type(), c.link() == null ? null : c.link().entityId(),
                deadline == null ? null : deadline.title(), deadline == null ? null : deadline.dueAt(),
                deadline == null ? null : deadline.completed(), c.isCompletedByLink(),
                c.currentStreakOn(time.today()), c.bestStreak(), c.lastActiveDay(), c.hasDependencies(), ms.size(),
                (int) ms.stream().filter(Milestone::completed).count(),
                ms.stream().map(m -> MilestoneResponse.from(c, m, xp.getOrDefault(m.id(), 0), owned)).toList(),
                c.originId(), c.originOwnerId(), c.originOwnerName(), c.sessionTarget(), c.sessionsCompleted(),
                c.tracksTrainingSessions(), c.createdAt(), c.updatedAt());
    }

    public static ChallengeResponse own(Challenge c, ResponseTime time) {
        return from(c, true, null, time);
    }
}
