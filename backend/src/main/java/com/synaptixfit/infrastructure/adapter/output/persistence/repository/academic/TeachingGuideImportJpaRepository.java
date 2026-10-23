package com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.TeachingGuideImportEntity;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.transaction.annotation.Transactional;

/** Spring Data para {@code importaciones_plan_docente}. */
public interface TeachingGuideImportJpaRepository extends JpaRepository<TeachingGuideImportEntity, UUID> {

    Optional<TeachingGuideImportEntity> findByIdAndUserId(UUID id, UUID userId);

    /**
     * Cambio de estado condicional: solo toca la fila si sigue en {@code expected}. Lleva su propia
     * transacción (o se une a la del caso de uso) porque el análisis en segundo plano no tiene una.
     */
    @Transactional
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("update TeachingGuideImportEntity i set i.status = :status, i.result = :result, i.errorCode = :errorCode, "
            + "i.appliedSubjectId = :appliedSubjectId, i.updatedAt = :updatedAt "
            + "where i.id = :id and i.status = :expected")
    int transition(UUID id, String expected, String status, String result, String errorCode, UUID appliedSubjectId,
                   Instant updatedAt);
}
