package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.application.port.input.planner.RecordFocusSessionUseCase;
import com.synaptixfit.domain.model.planner.FocusSession;
import com.synaptixfit.domain.model.planner.FocusXpStatus;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Fase Pomodoro registrada. {@code xpAwarded} es la XP que ha dado y {@code xpStatus} el motivo
 * (AWARDED, DAILY_CAP_REACHED o NOT_ELIGIBLE), calculado en el dominio ({@code FocusRewards}).
 */
public record FocusSessionResponse(UUID id, FocusSession.FocusPhase phase, int durationMinutes, int cycles,
                                   boolean completed, LocalDate date, UUID blockId, UUID subjectId, int xpAwarded,
                                   FocusXpStatus xpStatus, Instant createdAt) {

    public static FocusSessionResponse from(RecordFocusSessionUseCase.Result result) {
        FocusSession s = result.session();
        return new FocusSessionResponse(s.id(), s.phase(), s.durationMinutes(), s.cycles(), s.completed(), s.date(),
                s.blockId(), s.subjectId(), s.xpAwarded(), result.xpStatus(), s.createdAt());
    }
}
