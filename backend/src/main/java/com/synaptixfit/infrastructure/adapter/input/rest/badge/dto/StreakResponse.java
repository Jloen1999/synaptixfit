package com.synaptixfit.infrastructure.adapter.input.rest.badge.dto;

import com.synaptixfit.domain.model.badge.StreakStatus;
import java.util.List;

/**
 * Racha diaria (días con sesión de entrenamiento o check-in). {@code atRisk}: quedan menos de 4 h
 * del día sin actividad. {@code nextMilestone} nulo si ya se superaron 7/30/100/365.
 */
public record StreakResponse(int currentDays, int bestDays, boolean activeToday, boolean atRisk,
                             Integer nextMilestone, int daysToNextMilestone, double milestoneProgress,
                             List<Integer> reachedMilestones) {

    public static StreakResponse from(StreakStatus s) {
        return new StreakResponse(s.currentDays(), s.bestDays(), s.activeToday(), s.atRisk(), s.nextMilestone(),
                s.daysToNextMilestone(), s.milestoneProgress(), s.reachedMilestones());
    }
}
