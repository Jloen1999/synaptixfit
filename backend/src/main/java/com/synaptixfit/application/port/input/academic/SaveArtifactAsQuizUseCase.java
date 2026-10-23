package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.SavedQuiz;
import java.util.List;
import java.util.UUID;

/** Guarda preguntas generadas para repasar: crea un apunte con su contenido, su material y su banco. */
public interface SaveArtifactAsQuizUseCase {

    record Command(UUID userId, UUID subjectId, String title, List<QuestionDraft> questions) {}

    SavedQuiz saveAsQuiz(Command command);
}
