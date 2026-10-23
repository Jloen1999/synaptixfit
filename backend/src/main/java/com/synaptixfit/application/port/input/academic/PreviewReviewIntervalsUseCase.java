package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.ReviewPreview;
import java.util.UUID;

/** Intervalos resultantes para los 6 niveles de autoevaluación con la fatiga física de hoy. */
public interface PreviewReviewIntervalsUseCase {

    ReviewPreview previewReview(UUID userId, UUID materialId);
}
