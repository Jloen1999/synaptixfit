package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TeachingGuideDocument;
import java.util.UUID;

/** Extrae con IA la guía docente de un PDF de la asignatura y la guarda (sobrescribe la anterior). */
public interface GenerateTeachingGuideUseCase {

    TeachingGuideDocument generateTeachingGuide(UUID userId, UUID subjectId, UUID fileId);
}
