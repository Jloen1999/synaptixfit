package com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.AiDocumentEntity;
import java.util.Collection;
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

    List<AiDocumentEntity> findByUserIdAndSourceTypeAndTypeAndSourceIdIn(UUID userId, String sourceType, String type,
                                                                        Collection<String> sourceIds);

    List<AiDocumentEntity> findByUserIdAndSourceTypeAndSourceId(UUID userId, String sourceType, String sourceId);

    /** Pares (fuente, tipo) de varias fuentes del usuario, sin leer el contenido. */
    @Query("select d.sourceId, d.type from AiDocumentEntity d where d.userId = :userId "
            + "and d.sourceType = :sourceType and d.sourceId in :sourceIds")
    List<Object[]> findTypesBySources(UUID userId, String sourceType, Collection<String> sourceIds);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from AiDocumentEntity d where d.userId = :userId and d.sourceType = :sourceType "
            + "and d.sourceId = :sourceId")
    void deleteBySource(UUID userId, String sourceType, String sourceId);
}
