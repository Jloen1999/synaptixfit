package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.challenge.LinkedDeadline;
import com.synaptixfit.domain.model.challenge.Milestone;
import com.synaptixfit.domain.model.challenge.MilestoneStatus;
import com.synaptixfit.domain.model.challenge.StudyBlockProgress;
import com.synaptixfit.domain.model.challenge.UnlockCondition;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Tarea de un reto. {@code progress} y {@code weight} en puntos porcentuales (0-100); el peso lo deriva el
 * servidor de la dificultad. {@code xpReward} es el XP real con el tope del reto (el que dio si está
 * completada). {@code completedByLink}: la completa su entrega/examen ({@code linkTitle}, {@code linkDueAt},
 * {@code linkCompleted}) o sus bloques del calendario ({@code studyBlocksTotal}/{@code studyBlocksCompleted}),
 * no un toque. Con un día de rutina ({@code ROUTINE_DAY}), {@code linkTitle} es el nombre de la rutina,
 * {@code linkDueAt} es nulo y {@code linkWeekNumber}/{@code linkDayNumber} dicen qué día (1 = lunes).
 * Los datos del vínculo solo van en retos propios.
 */
public record MilestoneResponse(UUID id, String title, double weight, int order, double progress, boolean completed,
                                MilestoneStatus status, List<UUID> dependencies, UnlockCondition conditionType,
                                int conditionN, Difficulty difficulty, int xpReward, int xpAwarded, UUID subjectId,
                                LinkType linkedEntityType, UUID linkedEntityId, String linkTitle, Instant linkDueAt,
                                Boolean linkCompleted, boolean completedByLink, int studyBlocksTotal,
                                int studyBlocksCompleted, UUID noteId, UUID fileId, Integer linkWeekNumber,
                                Integer linkDayNumber) {

    public static MilestoneResponse from(Challenge c, Milestone m, int xpReward, boolean owned) {
        LinkedDeadline deadline = owned ? c.linkedDeadline(m.link()).orElse(null) : null;
        StudyBlockProgress blocks = owned ? c.studyBlocksOf(m.id()) : StudyBlockProgress.NONE;
        return new MilestoneResponse(m.id(), m.title(), m.weight(), m.order(), m.progress(), m.completed(),
                m.status(), m.dependencies(), m.condition(), m.conditionN(), m.difficulty(), xpReward,
                m.xpAwarded(), m.subjectId(), m.link() == null ? null : m.link().type(),
                m.link() == null ? null : m.link().entityId(), deadline == null ? null : deadline.title(),
                deadline == null ? null : deadline.dueAt(), deadline == null ? null : deadline.completed(),
                c.isCompletedByLink(m), blocks.total(), blocks.completed(), m.noteId(), m.fileId(),
                deadline == null ? null : deadline.weekNumber(), deadline == null ? null : deadline.dayNumber());
    }
}
