package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.ReviewOutcome;
import java.util.UUID;

/** Aplica un repaso SM-2-Physio (calidad 0-5 ajustada por fatiga), lo audita y programa el siguiente. */
public interface ReviewStudyMaterialUseCase {

    ReviewOutcome review(UUID userId, UUID materialId, int quality);
}
