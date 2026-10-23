package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TeachingGuide;
import java.util.UUID;

/**
 * Aplica el plan docente revisado: crea la asignatura (o completa la elegida), guarda la guía,
 * deja el PDF entre sus archivos y, si se pide, crea en el planificador las pruebas con fecha.
 */
public interface ApplyTeachingGuideImportUseCase {

    /** {@code subjectId} nulo crea una asignatura nueva; {@code guide} nula aplica lo extraído tal cual. */
    record Command(UUID userId, UUID importId, UUID subjectId, TeachingGuide guide, boolean createDeadlines) {
    }

    record Result(UUID subjectId, boolean subjectCreated, int deadlinesRequested) {
    }

    Result apply(Command command);
}
