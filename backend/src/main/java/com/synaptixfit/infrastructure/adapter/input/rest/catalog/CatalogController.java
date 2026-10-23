package com.synaptixfit.infrastructure.adapter.input.rest.catalog;

import com.synaptixfit.application.port.input.catalog.GetCatalogSubjectUseCase;
import com.synaptixfit.application.port.input.catalog.GetDegreeUseCase;
import com.synaptixfit.application.port.input.catalog.GetUniversityUseCase;
import com.synaptixfit.application.port.input.catalog.ListCentersUseCase;
import com.synaptixfit.application.port.input.catalog.ListDegreesUseCase;
import com.synaptixfit.application.port.input.catalog.ListUniversitiesUseCase;
import com.synaptixfit.application.port.input.catalog.SearchCatalogSubjectsUseCase;
import com.synaptixfit.domain.model.catalog.CatalogSubjectFilter;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto.CatalogSubjectDetailResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto.CatalogSubjectResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto.CenterResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto.DegreeResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto.UniversityResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Catálogo académico de solo lectura (cualquier usuario autenticado). */
@Tag(name = "Catalog")
@RestController
@RequestMapping("/api/v1/catalog")
public class CatalogController {

    private final ListUniversitiesUseCase listUniversities;
    private final GetUniversityUseCase getUniversity;
    private final ListCentersUseCase listCenters;
    private final ListDegreesUseCase listDegrees;
    private final GetDegreeUseCase getDegree;
    private final SearchCatalogSubjectsUseCase searchSubjects;
    private final GetCatalogSubjectUseCase getSubject;

    public CatalogController(ListUniversitiesUseCase listUniversities, GetUniversityUseCase getUniversity,
                             ListCentersUseCase listCenters, ListDegreesUseCase listDegrees,
                             GetDegreeUseCase getDegree, SearchCatalogSubjectsUseCase searchSubjects,
                             GetCatalogSubjectUseCase getSubject) {
        this.listUniversities = listUniversities;
        this.getUniversity = getUniversity;
        this.listCenters = listCenters;
        this.listDegrees = listDegrees;
        this.getDegree = getDegree;
        this.searchSubjects = searchSubjects;
        this.getSubject = getSubject;
    }

    @GetMapping("/universities")
    public List<UniversityResponse> universities(@RequestParam(required = false) String q) {
        return listUniversities.listUniversities(q).stream().map(UniversityResponse::from).toList();
    }

    @GetMapping("/universities/{universityId}")
    public UniversityResponse university(@PathVariable UUID universityId) {
        return UniversityResponse.from(getUniversity.getUniversity(universityId));
    }

    @GetMapping("/universities/{universityId}/centers")
    public List<CenterResponse> centers(@PathVariable UUID universityId) {
        return listCenters.listCenters(universityId).stream().map(CenterResponse::from).toList();
    }

    @GetMapping("/universities/{universityId}/degrees")
    public List<DegreeResponse> degreesByUniversity(@PathVariable UUID universityId,
                                                    @RequestParam(required = false) String q) {
        return listDegrees.listDegreesByUniversity(universityId, q).stream().map(DegreeResponse::from).toList();
    }

    @GetMapping("/centers/{centerId}/degrees")
    public List<DegreeResponse> degreesByCenter(@PathVariable UUID centerId) {
        return listDegrees.listDegreesByCenter(centerId).stream().map(DegreeResponse::from).toList();
    }

    @GetMapping("/degrees/{degreeId}")
    public DegreeResponse degree(@PathVariable UUID degreeId) {
        return DegreeResponse.from(getDegree.getDegree(degreeId));
    }

    @GetMapping("/degrees/{degreeId}/subjects")
    public PageResponse<CatalogSubjectResponse> subjects(@PathVariable UUID degreeId,
                                                         @RequestParam(required = false) Integer course,
                                                         @RequestParam(required = false) Integer semester,
                                                         @RequestParam(required = false) String character,
                                                         @RequestParam(required = false) String q,
                                                         @RequestParam(defaultValue = "0") int page,
                                                         @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(searchSubjects.searchSubjects(degreeId,
                new CatalogSubjectFilter(course, semester, character, q), new PageRequest(page, size)),
                CatalogSubjectResponse::from);
    }

    @GetMapping("/subjects/{subjectId}")
    public CatalogSubjectDetailResponse subject(@PathVariable UUID subjectId) {
        return CatalogSubjectDetailResponse.from(getSubject.getSubject(subjectId));
    }
}
