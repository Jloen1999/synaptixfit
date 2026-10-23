package com.synaptixfit.domain.model.academic;

import java.time.Instant;
import java.util.UUID;

/** Guía docente guardada de una asignatura. */
public record TeachingGuideDocument(UUID subjectId, TeachingGuide guide, Instant updatedAt) {
}
