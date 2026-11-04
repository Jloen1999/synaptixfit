package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.ListSportActivitiesUseCase;
import com.synaptixfit.domain.model.planner.LoggedSportActivity;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.planner.LoggedActivityRepositoryPort;
import java.util.UUID;

/** Implementa {@link ListSportActivitiesUseCase} leyendo el deporte hecho con {@link LoggedActivityRepositoryPort}. */
public class SportActivityHistoryService implements ListSportActivitiesUseCase {

    private final LoggedActivityRepositoryPort activities;

    public SportActivityHistoryService(LoggedActivityRepositoryPort activities) {
        this.activities = activities;
    }

    @Override
    public PageResult<LoggedSportActivity> list(UUID userId, PageRequest page) {
        return activities.findSportActivities(userId, page);
    }
}
