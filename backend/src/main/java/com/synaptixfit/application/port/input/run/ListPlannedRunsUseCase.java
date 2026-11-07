package com.synaptixfit.application.port.input.run;

import com.synaptixfit.domain.model.run.PlannedRun;
import java.util.List;
import java.util.UUID;

/** Entrenos de carrera puestos en el calendario y aún por hacer, desde hoy y durante una semana. */
public interface ListPlannedRunsUseCase {

    List<PlannedRun> listPlanned(UUID userId);
}
