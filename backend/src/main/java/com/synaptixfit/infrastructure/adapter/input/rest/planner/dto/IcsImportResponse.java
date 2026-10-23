package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.application.port.input.planner.ImportIcsUseCase;

/** Resultado de la importación ICS. */
public record IcsImportResponse(ImportIcsUseCase.Match match, int totalEvents, int matchingEvents, int classes,
                                int exams, int deliveries, int created, int updated, boolean imported) {

    public static IcsImportResponse from(ImportIcsUseCase.Result r) {
        return new IcsImportResponse(r.match(), r.totalEvents(), r.matchingEvents(), r.classes(), r.exams(),
                r.deliveries(), r.created(), r.updated(), r.imported());
    }
}
