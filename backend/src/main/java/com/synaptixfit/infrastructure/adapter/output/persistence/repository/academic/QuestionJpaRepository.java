package com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.QuestionEntity;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

/** Spring Data para {@code preguntas}. */
public interface QuestionJpaRepository extends JpaRepository<QuestionEntity, UUID> {

    List<QuestionEntity> findByBankIdOrderByPositionAsc(UUID bankId);

    List<QuestionEntity> findByIdIn(Collection<UUID> ids);

    long countByBankId(UUID bankId);

    @Query("select q from QuestionEntity q, QuestionBankEntity b where q.id = :questionId and b.id = q.bankId "
            + "and b.userId = :userId")
    Optional<QuestionEntity> findOfUser(UUID questionId, UUID userId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from QuestionEntity q where q.bankId = :bankId")
    void deleteByBank(UUID bankId);
}
