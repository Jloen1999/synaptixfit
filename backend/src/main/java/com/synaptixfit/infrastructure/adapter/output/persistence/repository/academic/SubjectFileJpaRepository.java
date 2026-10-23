package com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.SubjectFileEntity;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

/** Spring Data para {@code archivos_asignatura}. */
public interface SubjectFileJpaRepository extends JpaRepository<SubjectFileEntity, UUID> {

    Optional<SubjectFileEntity> findByIdAndUserId(UUID id, UUID userId);

    List<SubjectFileEntity> findByUserIdAndSubjectIdOrderByCreatedAtDesc(UUID userId, UUID subjectId);

    boolean existsByObjectKey(String objectKey);

    @Query("select f.subjectId, count(f) from SubjectFileEntity f where f.userId = :userId "
            + "and f.subjectId in :subjectIds group by f.subjectId")
    List<Object[]> countBySubject(UUID userId, Collection<UUID> subjectIds);
}
