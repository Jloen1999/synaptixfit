package com.synaptixfit.domain.port.output.profile;

import java.util.UUID;

/** Lectura de las asignaturas del usuario (tabla del módulo académico) para el onboarding. */
public interface UserSubjectsQueryPort {

    /** Si el usuario tiene al menos una asignatura no archivada. */
    boolean hasActiveSubjects(UUID userId);
}
