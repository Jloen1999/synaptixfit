package com.synaptixfit.domain.model.profile;

import com.synaptixfit.domain.model.shared.Guard;

/** Objetivo principal recomendado con su justificación (en español). */
public record GoalSuggestion(TrainingGoal goal, String reason) {

    public GoalSuggestion {
        Guard.notNull(goal, "goal");
        reason = Guard.notBlank(reason, "reason");
    }
}
