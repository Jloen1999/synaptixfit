package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

import com.synaptixfit.domain.model.profile.GoalHistoryEntry;
import com.synaptixfit.domain.model.profile.TrainingGoal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Periodo del historial de objetivos. {@code active} = periodo abierto (sin fecha de fin). */
public record GoalHistoryResponse(UUID id, TrainingGoal goal, String goalLabel, TrainingGoal previousGoal,
                                  String previousGoalLabel, LocalDate startDate, LocalDate endDate, boolean active,
                                  List<UUID> routineIds) {

    public static GoalHistoryResponse from(GoalHistoryEntry e) {
        return new GoalHistoryResponse(e.id(), e.goal(), e.goal().label(), e.previousGoal(),
                e.previousGoal() == null ? null : e.previousGoal().label(), e.startDate(), e.endDate(), e.isOpen(),
                e.routineIds());
    }
}
