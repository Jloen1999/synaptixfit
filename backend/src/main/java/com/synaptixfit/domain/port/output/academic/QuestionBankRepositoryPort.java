package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionBank;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de bancos de preguntas y sus preguntas. */
public interface QuestionBankRepositoryPort {

    Optional<QuestionBank> findByIdAndUser(UUID id, UUID userId);

    Optional<QuestionBank> findByMaterial(UUID materialId);

    QuestionBank save(QuestionBank bank);

    /** Sustituye todas las preguntas del banco. */
    void replaceQuestions(UUID bankId, List<Question> questions);

    /** Preguntas del banco por orden. */
    List<Question> findQuestions(UUID bankId);

    List<Question> findQuestionsByIds(Collection<UUID> ids);

    /** Cuántas preguntas tiene el banco, sin cargarlas. */
    int countQuestions(UUID bankId);

    /** Pregunta cuyo banco pertenece al usuario. */
    Optional<Question> findQuestionOfUser(UUID questionId, UUID userId);
}
