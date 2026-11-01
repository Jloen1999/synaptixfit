package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.BlockDetailsInput;
import com.synaptixfit.domain.exception.planner.BlockOutsideChallengePeriodException;
import com.synaptixfit.domain.exception.planner.DeadlineNotFoundException;
import com.synaptixfit.domain.exception.planner.PlannerChallengeNotFoundException;
import com.synaptixfit.domain.exception.planner.PlannerRoutineNotFoundException;
import com.synaptixfit.domain.exception.planner.PlannerSubjectNotFoundException;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.ChallengeRef;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.RoutineRef;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.port.output.planner.ChallengeDirectoryPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.RoutineDirectoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.util.UUID;

/**
 * Valida los vínculos opcionales de un bloque contra la propiedad del usuario (asignatura, rutina con
 * su semana y día, reto, tarea de reto y entrega) y construye sus datos de dominio. Un vínculo ajeno
 * se trata como inexistente (404). La tarea debe ser del reto indicado (si no se indica, se toma su reto)
 * y el bloque debe caer en el periodo de ese reto (ADR 0028).
 */
final class BlockDetailsResolver {

    private final SubjectDirectoryPort subjects;
    private final RoutineDirectoryPort routines;
    private final ChallengeDirectoryPort challenges;
    private final DeadlineRepositoryPort deadlines;
    private final PlannerZone zone;

    BlockDetailsResolver(SubjectDirectoryPort subjects, RoutineDirectoryPort routines,
                         ChallengeDirectoryPort challenges, DeadlineRepositoryPort deadlines, PlannerZone zone) {
        this.subjects = subjects;
        this.routines = routines;
        this.challenges = challenges;
        this.deadlines = deadlines;
        this.zone = zone;
    }

    /** @param range franja del bloque (para comprobar el periodo del reto) */
    CalendarBlock.Details resolve(UUID userId, BlockDetailsInput in, TimeRange range) {
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
        UUID challengeId = in.challengeId();
        if (in.milestoneId() != null) {
            UUID owner = challenges.findMilestoneChallenge(userId, in.milestoneId())
                    .orElseThrow(() -> new PlannerChallengeNotFoundException(in.milestoneId()));
            // Una tarea de otro reto no vale: el bloque avanzaría un reto que no es el elegido.
            if (challengeId != null && !challengeId.equals(owner)) {
                throw new PlannerChallengeNotFoundException(in.milestoneId());
            }
            challengeId = owner;
        }
        checkChallengePeriod(userId, challengeId, range);
        if (in.deadlineId() != null && deadlines.findById(in.deadlineId())
                .filter(d -> d.userId().equals(userId)).isEmpty()) {
            throw new DeadlineNotFoundException(in.deadlineId());
        }
        return new CalendarBlock.Details(in.subjectId(), in.topics(), in.location(), in.priority(), in.isPrivate(),
                in.classKind(), routineId, weekId, dayId, challengeId, in.milestoneId(), in.deadlineId());
    }

    /** El bloque de un reto debe caer entre su inicio y su fin (por días); 404 si el reto no es del usuario. */
    void checkChallengePeriod(UUID userId, UUID challengeId, TimeRange range) {
        if (!fitsChallengePeriod(userId, challengeId, range)) {
            throw new BlockOutsideChallengePeriodException(challengeId);
        }
    }

    /** ¿Cabe el bloque en el periodo del reto? Siempre sí si no hay reto. */
    boolean fitsChallengePeriod(UUID userId, UUID challengeId, TimeRange range) {
        if (challengeId == null) {
            return true;
        }
        ChallengeRef challenge = challenges.findOwnedChallenge(userId, challengeId)
                .orElseThrow(() -> new PlannerChallengeNotFoundException(challengeId));
        return challenge.covers(range.start(), zone);
    }
}
