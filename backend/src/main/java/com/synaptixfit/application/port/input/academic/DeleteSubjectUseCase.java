package com.synaptixfit.application.port.input.academic;

import java.util.UUID;

/** Borra una asignatura con sus archivos (también del almacenamiento), materiales y asignación de semestre. Los apuntes quedan sin asignatura. */
public interface DeleteSubjectUseCase {

    void deleteSubject(UUID userId, UUID subjectId);
}
