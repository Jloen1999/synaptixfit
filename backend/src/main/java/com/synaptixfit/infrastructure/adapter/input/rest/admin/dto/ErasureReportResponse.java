package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import com.synaptixfit.domain.model.privacy.ErasureMode;
import com.synaptixfit.domain.model.privacy.ErasureReport;
import java.util.UUID;

/** Resultado de vaciar, anonimizar o eliminar una cuenta. */
public record ErasureReportResponse(UUID userId, ErasureMode mode, int deletedRecords, int storedFiles,
                                    int failedFileDeletions) {

    public static ErasureReportResponse from(ErasureReport r) {
        return new ErasureReportResponse(r.userId(), r.mode(), r.deletedRecords(), r.storedFiles(),
                r.failedFileDeletions());
    }
}
