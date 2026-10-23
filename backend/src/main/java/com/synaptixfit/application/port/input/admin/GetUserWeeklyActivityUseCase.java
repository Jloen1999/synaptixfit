package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.admin.WeeklyActivityPoint;
import java.util.List;
import java.util.UUID;

/** Serie semanal de actividad de las últimas {@code weeks} semanas (1-52), la actual incluida. */
public interface GetUserWeeklyActivityUseCase {

    List<WeeklyActivityPoint> getUserWeeklyActivity(UUID userId, int weeks);
}
