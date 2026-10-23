package com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.StudyMaterialEntity;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

/** Spring Data para {@code materiales_estudio}. */
public interface StudyMaterialJpaRepository extends JpaRepository<StudyMaterialEntity, UUID> {

    Optional<StudyMaterialEntity> findByIdAndUserId(UUID id, UUID userId);

    Optional<StudyMaterialEntity> findByUserIdAndOriginTypeAndOriginId(UUID userId, String originType, UUID originId);

    List<StudyMaterialEntity> findByUserIdOrderByCreatedAtDesc(UUID userId);

    List<StudyMaterialEntity> findByUserIdAndSubjectIdOrderByCreatedAtDesc(UUID userId, UUID subjectId);

    @Query("select m from StudyMaterialEntity m where m.userId = :userId and m.nextReviewAt is not null "
            + "and m.nextReviewAt <= :now and m.masteryState <> 'abandonado' order by m.nextReviewAt asc")
    List<StudyMaterialEntity> findDue(UUID userId, Instant now, Pageable page);
}
