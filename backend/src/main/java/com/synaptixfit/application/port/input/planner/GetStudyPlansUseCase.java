package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.StudyPlan;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.UUID;

/** Planes semanales del usuario, de la semana más reciente a la más antigua. */
public interface GetStudyPlansUseCase {

    PageResult<StudyPlan> getPlans(UUID userId, PageRequest page);
}
