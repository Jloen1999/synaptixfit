package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.ReviewRecord;
import java.util.List;
import java.util.UUID;

/** Historial de repasos de un material propio. */
public interface ListReviewHistoryUseCase {

    List<ReviewRecord> reviewHistory(UUID userId, UUID materialId);
}
