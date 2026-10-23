package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.StudyPlan;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.LocalDate;
import java.util.UUID;

/** Plan semanal (lunes a domingo). */
public record StudyPlanResponse(UUID id, String name, LocalDate weekStart, LocalDate weekEnd, Visibility visibility,
                                boolean xpAwarded, int xpPoints) {

    public static StudyPlanResponse from(StudyPlan p) {
        return new StudyPlanResponse(p.id(), p.name(), p.weekStart(), p.weekEnd(), p.visibility(), p.xpAwarded(),
                p.xpPoints());
    }
}
