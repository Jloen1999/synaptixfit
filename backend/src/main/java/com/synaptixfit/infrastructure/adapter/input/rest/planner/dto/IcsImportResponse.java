package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.application.port.input.planner.ImportIcsUseCase;
import java.util.List;

/** Resultado de la importación ICS, con los eventos importados (o los que trae el calendario si no se importó). */
public record IcsImportResponse(ImportIcsUseCase.Match match, int totalEvents, int matchingEvents, int classes,
                                int exams, int deliveries, int created, int updated, boolean imported,
                                List<ImportIcsUseCase.Item> items) {

    public static IcsImportResponse from(ImportIcsUseCase.Result r) {
        return new IcsImportResponse(r.match(), r.totalEvents(), r.matchingEvents(), r.classes(), r.exams(),
                r.deliveries(), r.created(), r.updated(), r.imported(), r.items());
    }
}
