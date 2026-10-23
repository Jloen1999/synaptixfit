package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.SubjectSemester;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de la asignación de asignaturas a curso y semestre. */
public interface SubjectSemesterRepositoryPort {

    List<SubjectSemester> findByUser(UUID userId);

    Optional<SubjectSemester> findBySubject(UUID userId, UUID subjectId);

    SubjectSemester save(SubjectSemester assignment);

    void deleteBySubject(UUID userId, UUID subjectId);
}
