package com.synaptixfit.infrastructure.adapter.input.rest.badge.dto;

import com.synaptixfit.domain.model.badge.StreakStatus;
import java.time.LocalDate;
import java.util.List;

/**
 * Racha diaria (días con sesión de entrenamiento o check-in). {@code atRisk}: quedan menos de 4 h
 * del día sin actividad. {@code nextMilestone} nulo si ya se superaron 7/30/100/365. Pausa (ADR 0042):
 * {@code pausedUntil}, último día de la pausa en curso (nulo si no hay); {@code pauseDaysLeft}: días que
 * duraría una pausa que empiece hoy; {@code canPause}: se ofrece «Pausar racha».
 */
public record StreakResponse(int currentDays, int bestDays, boolean activeToday, boolean atRisk,
                             Integer nextMilestone, int daysToNextMilestone, double milestoneProgress,
                             List<Integer> reachedMilestones, int freezesAvailable, List<LocalDate> frozenDays,
                             LocalDate pausedUntil, int pauseDaysLeft, boolean canPause) {

    public static StreakResponse from(StreakStatus s) {
        return new StreakResponse(s.currentDays(), s.bestDays(), s.activeToday(), s.atRisk(), s.nextMilestone(),
                s.daysToNextMilestone(), s.milestoneProgress(), s.reachedMilestones(), s.freezesAvailable(),
                s.frozenDays(), s.pause() == null ? null : s.pause().to(), s.pauseDaysLeft(), s.canPause());
    }
}
