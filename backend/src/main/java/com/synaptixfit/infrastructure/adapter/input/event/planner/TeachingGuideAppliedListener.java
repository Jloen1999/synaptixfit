package com.synaptixfit.infrastructure.adapter.input.event.planner;

import com.synaptixfit.application.port.input.planner.CreateDeadlinesFromGuideUseCase;
import com.synaptixfit.domain.event.academic.TeachingGuideApplied;
import com.synaptixfit.domain.model.academic.TeachingGuide.AssessmentKind;
import com.synaptixfit.domain.model.planner.DeadlineType;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/** Plan docente aplicado: sus pruebas con fecha pasan a «Entregas y exámenes» (sin duplicar). */
@Component
public class TeachingGuideAppliedListener {

    private final CreateDeadlinesFromGuideUseCase createFromGuide;

    public TeachingGuideAppliedListener(CreateDeadlinesFromGuideUseCase createFromGuide) {
        this.createFromGuide = createFromGuide;
    }

    @EventListener
    public void on(TeachingGuideApplied event) {
        createFromGuide.createFromGuide(new CreateDeadlinesFromGuideUseCase.Command(event.userId(), event.subjectId(),
                event.assessments().stream()
                        .map(a -> new CreateDeadlinesFromGuideUseCase.Item(a.title(), type(a.kind()), a.dueAt(),
                                a.description()))
                        .toList()));
    }

    /** Correspondencia explícita: si se añade un tipo de prueba, el compilador obliga a decidir aquí. */
    private static DeadlineType type(AssessmentKind kind) {
        return switch (kind) {
            case EXAM -> DeadlineType.EXAM;
            case ASSIGNMENT -> DeadlineType.ASSIGNMENT;
            case PRESENTATION -> DeadlineType.PRESENTATION;
            case OTHER -> DeadlineType.OTHER;
        };
    }
}
