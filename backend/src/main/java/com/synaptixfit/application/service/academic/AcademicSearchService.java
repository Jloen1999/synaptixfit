package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.SearchAcademicUseCase;
import com.synaptixfit.domain.model.academic.AcademicSearch;
import com.synaptixfit.domain.port.output.academic.AcademicSearchPort;
import java.util.List;
import java.util.UUID;

/** Implementa {@link SearchAcademicUseCase} con {@link AcademicSearchPort}: valida el texto y agrupa por tipo. */
public class AcademicSearchService implements SearchAcademicUseCase {

    private final AcademicSearchPort search;

    public AcademicSearchService(AcademicSearchPort search) {
        this.search = search;
    }

    @Override
    public AcademicSearch.Result search(UUID userId, String query) {
        AcademicSearch.Query q = AcademicSearch.Query.of(query);
        int limit = AcademicSearch.PER_GROUP + 1;
        return new AcademicSearch.Result(q.text(), List.of(
                AcademicSearch.Group.of(AcademicSearch.Kind.SUBJECT, search.subjects(userId, q.folded(), limit)),
                AcademicSearch.Group.of(AcademicSearch.Kind.NOTE, search.notes(userId, q.folded(), limit)),
                AcademicSearch.Group.of(AcademicSearch.Kind.FILE, search.files(userId, q.folded(), limit)),
                AcademicSearch.Group.of(AcademicSearch.Kind.DEADLINE, search.deadlines(userId, q.folded(), limit))));
    }
}
