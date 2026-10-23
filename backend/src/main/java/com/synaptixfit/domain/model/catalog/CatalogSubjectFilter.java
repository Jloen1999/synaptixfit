package com.synaptixfit.domain.model.catalog;

import com.synaptixfit.domain.model.shared.Guard;

/** Filtros de búsqueda de asignaturas del catálogo. Todos opcionales. */
public record CatalogSubjectFilter(Integer course, Integer semester, String character, String query) {

    public CatalogSubjectFilter {
        if (course != null) {
            Guard.range(course, "course", 1, 10);
        }
        if (semester != null) {
            Guard.range(semester, "semester", 0, 20);
        }
        character = character == null || character.isBlank() ? null : character.strip();
        query = query == null || query.isBlank() ? null : query.strip();
        if (query != null) {
            Guard.length(query, "q", 1, 100);
        }
    }

    public static CatalogSubjectFilter none() {
        return new CatalogSubjectFilter(null, null, null, null);
    }
}
