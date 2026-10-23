package com.synaptixfit.domain.model.catalog;

import java.util.List;

/** Ficha completa de una asignatura del catálogo. {@code evaluation} puede ser nulo. */
public record CatalogSubjectDetail(CatalogSubject subject, Degree degree, List<String> bibliography,
                                   List<String> professors, EvaluationCriteria evaluation,
                                   List<String> prerequisites) {

    public CatalogSubjectDetail {
        bibliography = List.copyOf(bibliography);
        professors = List.copyOf(professors);
        prerequisites = List.copyOf(prerequisites);
    }
}
