package com.synaptixfit.domain.model.profile.enrollment;

import java.util.List;

/**
 * Lo que la IA lee de un documento de matrícula ya sin datos personales: centro, titulación, curso
 * académico y las asignaturas matriculadas. Cualquier campo puede faltar.
 */
public record EnrollmentReading(String university, String center, String degree, String academicYear,
                                List<EnrolledSubject> subjects) {

    public EnrollmentReading {
        subjects = subjects == null ? List.of() : List.copyOf(subjects);
    }

    /**
     * @param course        curso de la titulación (1, 2…)
     * @param period        cuándo se imparte tal como lo dice el documento (p. ej. 1S, 2S, A)
     * @param timesEnrolled veces que se ha matriculado (1 = primera)
     */
    public record EnrolledSubject(String code, String name, Integer course, Double credits, String period,
                                  Integer timesEnrolled) {
    }
}
