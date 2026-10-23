package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.challenge.Milestone;
import com.synaptixfit.domain.model.challenge.MilestoneStatus;
import com.synaptixfit.domain.model.challenge.UnlockCondition;
import java.util.List;
import java.util.UUID;

/** Tarea de un reto. {@code progress} y {@code weight} en puntos porcentuales (0-100). */
public record MilestoneResponse(UUID id, String title, double weight, int order, double progress, boolean completed,
                                MilestoneStatus status, List<UUID> dependencies, UnlockCondition conditionType,
                                int conditionN, Difficulty difficulty, int xpReward, int xpAwarded, UUID subjectId,
                                LinkType linkedEntityType, UUID linkedEntityId, UUID noteId, UUID fileId) {

    public static MilestoneResponse from(Milestone m) {
        return new MilestoneResponse(m.id(), m.title(), m.weight(), m.order(), m.progress(), m.completed(),
                m.status(), m.dependencies(), m.condition(), m.conditionN(), m.difficulty(), m.difficulty().xp(),
                m.xpAwarded(), m.subjectId(), m.link() == null ? null : m.link().type(),
                m.link() == null ? null : m.link().entityId(), m.noteId(), m.fileId());
    }
}
