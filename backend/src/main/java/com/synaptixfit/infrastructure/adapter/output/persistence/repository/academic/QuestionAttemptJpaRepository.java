package com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.QuestionAttemptEntity;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code intentos_pregunta}. */
public interface QuestionAttemptJpaRepository extends JpaRepository<QuestionAttemptEntity, UUID> {

    List<QuestionAttemptEntity> findByUserIdAndQuestionIdIn(UUID userId, Collection<UUID> questionIds);
}
