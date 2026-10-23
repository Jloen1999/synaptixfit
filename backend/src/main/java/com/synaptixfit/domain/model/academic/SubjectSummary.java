package com.synaptixfit.domain.model.academic;

/** Asignatura con los conteos de apuntes y archivos que muestra el panel académico. */
public record SubjectSummary(Subject subject, long noteCount, long fileCount) {
}
