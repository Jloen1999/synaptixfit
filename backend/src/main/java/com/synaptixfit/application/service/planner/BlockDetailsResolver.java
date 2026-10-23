package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.BlockDetailsInput;
import com.synaptixfit.domain.exception.planner.DeadlineNotFoundException;
import com.synaptixfit.domain.exception.planner.PlannerChallengeNotFoundException;
import com.synaptixfit.domain.exception.planner.PlannerRoutineNotFoundException;
import com.synaptixfit.domain.exception.planner.PlannerSubjectNotFoundException;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.RoutineRef;
import com.synaptixfit.domain.port.output.planner.ChallengeDirectoryPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.RoutineDirectoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.util.UUID;

/**
 * Valida los vínculos opcionales de un bloque contra la propiedad del usuario (asignatura, rutina con
 * su semana y día, reto, tarea de reto y entrega) y construye sus datos de dominio. Un vínculo ajeno
 * se trata como inexistente (404).
 */
final class BlockDetailsResolver {

    private final SubjectDirectoryPort subjects;
    private final RoutineDirectoryPort routines;
    private final ChallengeDirectoryPort challenges;
    private final DeadlineRepositoryPort deadlines;

    BlockDetailsResolver(SubjectDirectoryPort subjects, RoutineDirectoryPort routines,
                         ChallengeDirectoryPort challenges, DeadlineRepositoryPort deadlines) {
        this.subjects = subjects;
        this.routines = routines;
        this.challenges = challenges;
        this.deadlines = deadlines;
    }

    CalendarBlock.Details resolve(UUID userId, BlockDetailsInput in) {
        if (in.subjectId() != null && subjects.findOwned(userId, in.subjectId()).isEmpty()) {
            throw new PlannerSubjectNotFoundException(in.subjectId());
        }
        UUID routineId = in.routineId();
        UUID weekId = in.routineWeekId();
        UUID dayId = in.routineDayId();
        if (routineId != null) {
            RoutineRef routine = routines.findOwnedWithDays(userId, routineId)
                    .orElseThrow(() -> new PlannerRoutineNotFoundException(routineId));
            if (dayId != null) {
                RoutineRef.Day day = routine.days().stream().filter(d -> d.id().equals(dayId)).findFirst()
                        .orElseThrow(() -> new PlannerRoutineNotFoundException(dayId));
                weekId = day.weekId();
            } else if (weekId != null) {
                UUID w = weekId;
                if (routine.days().stream().noneMatch(d -> d.weekId().equals(w))) {
                    throw new PlannerRoutineNotFoundException(weekId);
                }
            }
        } else if (weekId != null || dayId != null) {
            throw new PlannerRoutineNotFoundException(dayId != null ? dayId : weekId);
        }
        if (in.challengeId() != null && !challenges.ownsChallenge(userId, in.challengeId())) {
            throw new PlannerChallengeNotFoundException(in.challengeId());
        }
        if (in.milestoneId() != null && !challenges.ownsMilestone(userId, in.milestoneId())) {
            throw new PlannerChallengeNotFoundException(in.milestoneId());
        }
        if (in.deadlineId() != null && deadlines.findById(in.deadlineId())
                .filter(d -> d.userId().equals(userId)).isEmpty()) {
            throw new DeadlineNotFoundException(in.deadlineId());
        }
        return new CalendarBlock.Details(in.subjectId(), in.topics(), in.location(), in.priority(), in.isPrivate(),
                in.classKind(), routineId, weekId, dayId, in.challengeId(), in.milestoneId(), in.deadlineId());
    }
}
