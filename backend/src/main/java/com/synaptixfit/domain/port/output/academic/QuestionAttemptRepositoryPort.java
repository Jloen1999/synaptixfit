package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.QuestionAttempt;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

/** Persistencia de intentos de respuesta. */
public interface QuestionAttemptRepositoryPort {

    QuestionAttempt save(QuestionAttempt attempt);

    List<QuestionAttempt> findByUserAndQuestions(UUID userId, Collection<UUID> questionIds);
}
