package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.LoggedSportActivity;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.UUID;

/** Partidos y actividades hechos fuera de las sesiones de rutina, para el historial de entrenos. */
public interface ListSportActivitiesUseCase {

    PageResult<LoggedSportActivity> list(UUID userId, PageRequest page);
}
