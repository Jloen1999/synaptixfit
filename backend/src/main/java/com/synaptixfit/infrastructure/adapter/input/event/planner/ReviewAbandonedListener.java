package com.synaptixfit.infrastructure.adapter.input.event.planner;

import com.synaptixfit.application.port.input.planner.CancelReviewBlocksUseCase;
import com.synaptixfit.domain.event.academic.ReviewAbandoned;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/** Material quitado del repaso: se borran sus bloques de repaso pendientes del calendario. */
@Component
public class ReviewAbandonedListener {

    private final CancelReviewBlocksUseCase cancelReviewBlocks;

    public ReviewAbandonedListener(CancelReviewBlocksUseCase cancelReviewBlocks) {
        this.cancelReviewBlocks = cancelReviewBlocks;
    }

    @EventListener
    public void on(ReviewAbandoned event) {
        cancelReviewBlocks.cancelReviewBlocks(event.userId(), event.studyMaterialId());
    }
}
