package com.synaptixfit.domain.model.academic;

/**
 * Asignatura con los conteos de apuntes y archivos y lo próximo que tiene ({@link SubjectAgenda}): lo que muestra el
 * panel académico.
 */
public record SubjectSummary(Subject subject, long noteCount, long fileCount, SubjectAgenda agenda) {

    public SubjectSummary {
        agenda = agenda == null ? SubjectAgenda.EMPTY : agenda;
    }

    public SubjectSummary(Subject subject, long noteCount, long fileCount) {
        this(subject, noteCount, fileCount, SubjectAgenda.EMPTY);
    }
}
