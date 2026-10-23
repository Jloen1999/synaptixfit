package com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.SubjectEntity;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code asignaturas}. */
public interface SubjectJpaRepository extends JpaRepository<SubjectEntity, UUID> {

    Optional<SubjectEntity> findByIdAndUserId(UUID id, UUID userId);

    List<SubjectEntity> findByUserIdOrderByNameAsc(UUID userId);

    List<SubjectEntity> findByUserIdAndArchivedOrderByNameAsc(UUID userId, boolean archived);

    List<SubjectEntity> findByUserIdAndCatalogSubjectIdIn(UUID userId, Collection<UUID> catalogSubjectIds);
}
