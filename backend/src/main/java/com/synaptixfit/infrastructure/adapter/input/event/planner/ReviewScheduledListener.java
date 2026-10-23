package com.synaptixfit.infrastructure.adapter.input.event.planner;

import com.synaptixfit.application.port.input.planner.ScheduleReviewBlockUseCase;
import com.synaptixfit.domain.event.academic.ReviewScheduled;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/** Nueva fecha de repaso SM-2: se crea el bloque de repaso en el calendario (si no existe ya uno pendiente). */
@Component
public class ReviewScheduledListener {

    private final ScheduleReviewBlockUseCase scheduleReview;

    public ReviewScheduledListener(ScheduleReviewBlockUseCase scheduleReview) {
        this.scheduleReview = scheduleReview;
    }

    @EventListener
    public void on(ReviewScheduled event) {
        scheduleReview.scheduleReview(new ScheduleReviewBlockUseCase.Command(event.userId(), event.studyMaterialId(),
                event.subjectId(), event.title(), event.dueAt()));
    }
}
