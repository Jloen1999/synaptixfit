package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Ubicación de una asignatura del usuario en un curso (1-10) y semestre (1-2). Pensado para las
 * transversales u optativas del catálogo, que no tienen temporalidad fija.
 */
public record SubjectSemester(UUID id, UUID userId, UUID subjectId, int course, int semester, Instant createdAt) {

    public SubjectSemester {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(subjectId, "subjectId");
        Guard.range(course, "course", 1, 10);
        Guard.range(semester, "semester", 1, 2);
        Objects.requireNonNull(createdAt, "createdAt");
    }

    public SubjectSemester reassign(int newCourse, int newSemester) {
        return new SubjectSemester(id, userId, subjectId, newCourse, newSemester, createdAt);
    }
}
