package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionBank;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de bancos de preguntas y sus preguntas. */
public interface QuestionBankRepositoryPort {

    Optional<QuestionBank> findByIdAndUser(UUID id, UUID userId);

    Optional<QuestionBank> findByMaterial(UUID materialId);

    QuestionBank save(QuestionBank bank);

    /** Sustituye todas las preguntas del banco. */
    void replaceQuestions(UUID bankId, List<Question> questions);

    /** Añade preguntas al banco sin tocar las que tiene (ni su historial). */
    void addQuestions(UUID bankId, List<Question> questions);

    /** Preguntas del banco por orden. */
    List<Question> findQuestions(UUID bankId);

    List<Question> findQuestionsByIds(Collection<UUID> ids);

    /** Cuántas preguntas tiene el banco, sin cargarlas. */
    int countQuestions(UUID bankId);

    /**
     * Preguntas de varios materiales de una vez (del banco más reciente de cada uno, como {@link #findByMaterial}),
     * por id de material y en el orden del banco. Los materiales sin banco o sin preguntas no aparecen.
     */
    Map<UUID, List<Question>> findQuestionsByMaterials(Collection<UUID> materialIds);

    /** Pregunta cuyo banco pertenece al usuario. */
    Optional<Question> findQuestionOfUser(UUID questionId, UUID userId);
}
