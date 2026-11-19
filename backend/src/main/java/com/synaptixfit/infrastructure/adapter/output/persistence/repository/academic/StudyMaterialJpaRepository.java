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

    /** Repasos vencidos por asignatura; {@code excluded} es el estado que no se repasa (abandonado). */
    @Query("select m.subjectId as subjectId, count(m) as total from StudyMaterialEntity m where m.userId = :userId "
            + "and m.subjectId is not null and m.nextReviewAt is not null and m.nextReviewAt <= :now "
            + "and m.masteryState <> :excluded group by m.subjectId")
    List<DueBySubjectRow> countDueBySubject(UUID userId, Instant now, String excluded);

    /** Proyección de {@link #countDueBySubject}. */
    interface DueBySubjectRow {
        UUID getSubjectId();

        long getTotal();
    }

    /** Solo id y fecha de los repasos programados en [from, to): para repartirlos sin picos. */
    @Query("select m.id as id, m.nextReviewAt as nextReviewAt from StudyMaterialEntity m where m.userId = :userId "
            + "and m.nextReviewAt >= :from and m.nextReviewAt < :to and m.masteryState <> 'abandonado'")
    List<ScheduledReviewRow> findScheduled(UUID userId, Instant from, Instant to);

    /** Proyección de {@link #findScheduled}. */
    interface ScheduledReviewRow {
        UUID getId();

        Instant getNextReviewAt();
    }
}
