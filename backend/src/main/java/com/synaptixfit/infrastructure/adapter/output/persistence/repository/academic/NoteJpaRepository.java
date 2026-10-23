package com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.NoteEntity;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;

/** Spring Data para {@code apuntes}. */
public interface NoteJpaRepository extends JpaRepository<NoteEntity, UUID>, JpaSpecificationExecutor<NoteEntity> {

    Optional<NoteEntity> findByIdAndUserId(UUID id, UUID userId);

    List<NoteEntity> findByUserIdAndVisibilityNot(UUID userId, String visibility);

    @Query("select n.subjectId, count(n) from NoteEntity n where n.userId = :userId and n.subjectId in :subjectIds "
            + "group by n.subjectId")
    List<Object[]> countBySubject(UUID userId, Collection<UUID> subjectIds);
}
