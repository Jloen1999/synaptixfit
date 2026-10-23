package com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.AiDocumentEntity;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

/** Spring Data para {@code documentos_ia}. */
public interface AiDocumentJpaRepository extends JpaRepository<AiDocumentEntity, UUID> {

    Optional<AiDocumentEntity> findByUserIdAndSourceTypeAndSourceIdAndType(UUID userId, String sourceType,
                                                                            String sourceId, String type);

    List<AiDocumentEntity> findByUserIdAndSourceTypeAndSourceId(UUID userId, String sourceType, String sourceId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from AiDocumentEntity d where d.userId = :userId and d.sourceType = :sourceType "
            + "and d.sourceId = :sourceId")
    void deleteBySource(UUID userId, String sourceType, String sourceId);
}
