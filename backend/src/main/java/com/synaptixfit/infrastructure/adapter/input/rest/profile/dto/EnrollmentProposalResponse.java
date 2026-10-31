package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

import com.synaptixfit.domain.model.profile.enrollment.EnrollmentProposal;
import java.util.List;
import java.util.UUID;

/**
 * Propuesta de importación de la matrícula. {@code universityId}/{@code degreeId} son nulos si no se
 * reconocen en el catálogo; cada asignatura trae su equivalente del catálogo (o nulo) y si ya la tiene.
 */
public record EnrollmentProposalResponse(String universityName, UUID universityId, String centerName,
                                         String degreeName, UUID degreeId, String academicYear,
                                         List<Subject> subjects) {

    public record Subject(String code, String name, Integer course, Double credits, String period,
                          Integer timesEnrolled, UUID catalogSubjectId, boolean alreadyAdded) {
    }

    public static EnrollmentProposalResponse from(EnrollmentProposal p) {
        var r = p.reading();
        return new EnrollmentProposalResponse(
                p.university() != null ? p.university().name() : r.university(),
                p.university() != null ? p.university().id() : null,
                p.degree() != null && p.degree().centerName() != null ? p.degree().centerName() : r.center(),
                p.degree() != null ? p.degree().name() : r.degree(),
                p.degree() != null ? p.degree().id() : null,
                r.academicYear(),
                p.subjects().stream().map(s -> new Subject(s.source().code(),
                        s.catalogName() != null ? s.catalogName() : s.source().name(), s.source().course(),
                        s.source().credits(), s.source().period(), s.source().timesEnrolled(), s.catalogSubjectId(),
                        s.alreadyAdded())).toList());
    }
}
