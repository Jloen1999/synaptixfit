package com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.QuestionBankEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code bancos_preguntas}. */
public interface QuestionBankJpaRepository extends JpaRepository<QuestionBankEntity, UUID> {

    Optional<QuestionBankEntity> findByIdAndUserId(UUID id, UUID userId);

    Optional<QuestionBankEntity> findFirstByMaterialIdOrderByGeneratedAtDesc(UUID materialId);
}
