package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.SubjectFile;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de los metadatos de archivos de asignatura. */
public interface SubjectFileRepositoryPort {

    Optional<SubjectFile> findByIdAndUser(UUID id, UUID userId);

    /** Archivos de la asignatura, los más recientes primero. */
    List<SubjectFile> findBySubject(UUID userId, UUID subjectId);

    boolean existsByObjectKey(String objectKey);

    SubjectFile save(SubjectFile file);

    void delete(UUID id);
}
