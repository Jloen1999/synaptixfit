package com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.SubjectSemesterEntity;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

/** Spring Data para {@code asignaturas_usuario_semestre}. */
public interface SubjectSemesterJpaRepository extends JpaRepository<SubjectSemesterEntity, UUID> {

    List<SubjectSemesterEntity> findByUserIdOrderByCourseAscSemesterAsc(UUID userId);

    Optional<SubjectSemesterEntity> findByUserIdAndSubjectId(UUID userId, UUID subjectId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from SubjectSemesterEntity s where s.userId = :userId and s.subjectId = :subjectId")
    void deleteByUserAndSubject(UUID userId, UUID subjectId);
}
