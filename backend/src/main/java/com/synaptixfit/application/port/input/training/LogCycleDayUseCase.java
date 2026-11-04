package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.CycleEnergy;
import com.synaptixfit.domain.model.training.CycleOverview;
import com.synaptixfit.domain.model.training.CycleSymptom;
import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;

/** Apunta (o corrige) un día del ciclo; exige el seguimiento activo. */
public interface LogCycleDayUseCase {

    record Command(UUID userId, LocalDate date, boolean period, CycleEnergy energy, Set<CycleSymptom> symptoms,
                   String note) {
    }

    CycleOverview log(Command command);
}
