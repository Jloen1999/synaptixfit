package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import com.synaptixfit.application.port.input.academic.SearchAcademicUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.AcademicSearchResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Buscador único de Académico (ADR 0036): {@code GET /api/v1/academic/search?q=}. */
@Tag(name = "Academic - Search")
@RestController
@RequestMapping("/api/v1/academic/search")
public class AcademicSearchController {

    private final SearchAcademicUseCase search;

    public AcademicSearchController(SearchAcademicUseCase search) {
        this.search = search;
    }

    @GetMapping
    public AcademicSearchResponse search(@CurrentUserId UUID userId, @RequestParam String q) {
        return AcademicSearchResponse.from(search.search(userId, q));
    }
}
