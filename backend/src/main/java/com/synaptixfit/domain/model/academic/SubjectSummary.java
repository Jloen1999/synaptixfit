package com.synaptixfit.domain.model.academic;

/**
 * Asignatura con lo que muestra Académico: conteos de apuntes y archivos, lo próximo ({@link SubjectAgenda}), su curso
 * y cuatrimestre ({@code courseTerm}, nulo si no se sabe), los temas hechos de la guía docente ({@code syllabus},
 * nulo sin guía) y los repasos que tocan hoy ({@code dueReviews}).
 */
public record SubjectSummary(Subject subject, long noteCount, long fileCount, SubjectAgenda agenda,
                             CourseTerm courseTerm, SyllabusCount syllabus, int dueReviews) {

    /** Temas hechos de los que tiene la guía docente («Temas 4 de 10»). */
    public record SyllabusCount(int done, int total) {

        public static SyllabusCount of(TeachingGuide guide) {
            int done = (int) guide.topics().stream().filter(TeachingGuide.Topic::completed).count();
            return new SyllabusCount(done, guide.topics().size());
        }
    }

    public SubjectSummary {
        agenda = agenda == null ? SubjectAgenda.EMPTY : agenda;
        dueReviews = Math.max(0, dueReviews);
    }

    public SubjectSummary(Subject subject, long noteCount, long fileCount, SubjectAgenda agenda) {
        this(subject, noteCount, fileCount, agenda, null, null, 0);
    }

    public SubjectSummary(Subject subject, long noteCount, long fileCount) {
        this(subject, noteCount, fileCount, SubjectAgenda.EMPTY);
    }
}
