package com.synaptixfit.infrastructure.adapter.input.rest.academic.dto;

import com.synaptixfit.domain.model.academic.AcademicSearch;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Resultados del buscador de Académico agrupados por tipo ({@code SUBJECT}, {@code NOTE}, {@code FILE}, {@code DEADLINE}). */
public record AcademicSearchResponse(String query, List<GroupResponse> groups) {

    public record GroupResponse(AcademicSearch.Kind kind, List<HitResponse> hits, boolean more) {
    }

    public record HitResponse(UUID id, String title, String context, UUID subjectId, Instant at, boolean exam) {
    }

    public static AcademicSearchResponse from(AcademicSearch.Result r) {
        return new AcademicSearchResponse(r.query(), r.groups().stream()
                .map(g -> new GroupResponse(g.kind(), g.hits().stream()
                        .map(h -> new HitResponse(h.id(), h.title(), h.context(), h.subjectId(), h.at(), h.exam()))
                        .toList(), g.more()))
                .toList());
    }
}
