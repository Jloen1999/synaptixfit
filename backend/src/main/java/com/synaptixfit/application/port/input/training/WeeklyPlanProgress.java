package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.WeeklyTrainingPlan;

/** Plan semanal con las sesiones completadas en esa semana y el cumplimiento (0-1). */
public record WeeklyPlanProgress(WeeklyTrainingPlan plan, int completedSessions) {

    public double compliance() {
        return plan.compliance(completedSessions);
    }
}
