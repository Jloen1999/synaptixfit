package com.synaptixfit.application.port.input.profile;

import java.util.List;
import java.util.UUID;

/** Añade lo que el usuario eligió de la propuesta de matrícula: su carrera y sus asignaturas. */
public interface ApplyEnrollmentUseCase {

    /**
     * @param degreeId          carrera del catálogo a vincular (opcional)
     * @param catalogSubjectIds asignaturas reconocidas en el catálogo
     * @param customSubjects    asignaturas que no están en el catálogo (se crean como propias)
     */
    record Command(UUID userId, UUID degreeId, List<UUID> catalogSubjectIds, List<CustomSubject> customSubjects) {

        public Command {
            catalogSubjectIds = catalogSubjectIds == null ? List.of() : List.copyOf(catalogSubjectIds);
            customSubjects = customSubjects == null ? List.of() : List.copyOf(customSubjects);
        }
    }

    record CustomSubject(String name, String code, Integer credits) {
    }

    /** Cuántas asignaturas se añadieron y si se vinculó la carrera. */
    record Result(int subjectsAdded, boolean degreeLinked) {
    }

    Result applyEnrollment(Command command);
}
