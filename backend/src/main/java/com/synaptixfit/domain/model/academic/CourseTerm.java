package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Guard;
import java.util.Optional;

/**
 * Curso (1-10) y cuatrimestre (1-2) de una asignatura: el único formato que enseña la app («2.º curso · 1.er
 * cuatri»). Lo guarda {@link SubjectSemester} y lo deduce la importación de la guía docente con {@link #fromGuide}.
 */
public record CourseTerm(int course, int term) {

    /** Un grado tiene dos cuatrimestres por curso. */
    static final int TERMS_PER_COURSE = 2;

    public CourseTerm {
        Guard.range(course, "course", 1, 10);
        Guard.range(term, "term", 1, TERMS_PER_COURSE);
    }

    /**
     * Pasa lo que dice la guía a curso y cuatrimestre. Las guías dan el semestre de dos maneras: el del grado
     * («Semestre 6») o el del curso («Curso 3 · Semestre 2»). Un semestre mayor que 2 es del grado: el 6 es el 2.º
     * cuatrimestre de 3.º. Con 1 o 2 solo vale si la guía da también el curso; sin él no se sabe si es el cuatrimestre
     * de 1.º o de otro curso, y se deja sin asignar (mejor nada que un curso equivocado).
     */
    public static Optional<CourseTerm> fromGuide(Integer courseYear, Integer semester) {
        if (semester == null || semester < 1) {
            return Optional.empty();
        }
        if (semester > TERMS_PER_COURSE) {
            int course = (semester + 1) / TERMS_PER_COURSE;
            int term = semester % TERMS_PER_COURSE == 1 ? 1 : 2;
            return course > 10 ? Optional.empty() : Optional.of(new CourseTerm(course, term));
        }
        if (courseYear == null || courseYear < 1 || courseYear > 10) {
            return Optional.empty();
        }
        return Optional.of(new CourseTerm(courseYear, semester));
    }
}
