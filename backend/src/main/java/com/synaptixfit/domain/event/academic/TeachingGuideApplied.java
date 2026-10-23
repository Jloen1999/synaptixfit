package com.synaptixfit.domain.event.academic;

import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.model.academic.TeachingGuide.AssessmentKind;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * El estudiante aplicó un plan docente a una asignatura. Lleva las pruebas con fecha para que el
 * planificador cree sus entregas y exámenes (sin duplicar los que ya existan).
 */
public record TeachingGuideApplied(UUID userId, UUID subjectId, List<DatedAssessment> assessments,
                                   Instant occurredAt) implements DomainEvent {

    public record DatedAssessment(String title, AssessmentKind kind, Instant dueAt, String description) {
    }

    public TeachingGuideApplied {
        assessments = assessments == null ? List.of() : List.copyOf(assessments);
    }
}
