package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SubjectFile;
import java.util.List;
import java.util.UUID;

/** Archivos de una asignatura propia, los más recientes primero. */
public interface ListSubjectFilesUseCase {

    List<SubjectFile> listFiles(UUID userId, UUID subjectId);
}
