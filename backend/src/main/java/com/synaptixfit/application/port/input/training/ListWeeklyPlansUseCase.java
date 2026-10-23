package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.UUID;

/** Planes semanales del usuario. */
public interface ListWeeklyPlansUseCase {

    PageResult<WeeklyPlanProgress> list(UUID userId, PageRequest page);
}
