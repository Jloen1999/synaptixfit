package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.application.port.input.planner.ScanScheduleUseCase;
import java.util.List;

/** Resultado del escaneo de horario. */
public record ScheduleScanResponse(int classesFound, int blocksCreated, int blocksUpdated,
                                   List<String> unmatchedSubjects) {

    public static ScheduleScanResponse from(ScanScheduleUseCase.Result r) {
        return new ScheduleScanResponse(r.classesFound(), r.blocksCreated(), r.blocksUpdated(), r.unmatchedSubjects());
    }
}
