package com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto;

import com.synaptixfit.domain.model.catalog.CatalogSubjectDetail;
import com.synaptixfit.domain.model.catalog.EvaluationCriteria;
import java.util.List;

/** Ficha de una asignatura del catálogo. {@code evaluation} es nulo si no hay criterios publicados. */
public record CatalogSubjectDetailResponse(CatalogSubjectResponse subject, DegreeResponse degree,
                                           List<String> bibliography, List<String> professors,
                                           EvaluationResponse evaluation, List<String> prerequisites) {

    /** Ponderación de la evaluación en porcentaje. */
    public record EvaluationResponse(double finalExamPercent, double continuousAssessmentPercent, double labPercent) {

        static EvaluationResponse from(EvaluationCriteria c) {
            return c == null ? null
                    : new EvaluationResponse(c.finalExamPercent(), c.continuousAssessmentPercent(), c.labPercent());
        }
    }

    public static CatalogSubjectDetailResponse from(CatalogSubjectDetail d) {
        return new CatalogSubjectDetailResponse(CatalogSubjectResponse.from(d.subject()),
                d.degree() == null ? null : DegreeResponse.from(d.degree()), d.bibliography(), d.professors(),
                EvaluationResponse.from(d.evaluation()), d.prerequisites());
    }
}
