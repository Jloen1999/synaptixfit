package com.synaptixfit.application.service.catalog;

import com.synaptixfit.application.port.input.catalog.GetCatalogSubjectUseCase;
import com.synaptixfit.application.port.input.catalog.GetDegreeUseCase;
import com.synaptixfit.application.port.input.catalog.GetUniversityUseCase;
import com.synaptixfit.application.port.input.catalog.ListCentersUseCase;
import com.synaptixfit.application.port.input.catalog.ListDegreesUseCase;
import com.synaptixfit.application.port.input.catalog.ListUniversitiesUseCase;
import com.synaptixfit.application.port.input.catalog.SearchCatalogSubjectsUseCase;
import com.synaptixfit.domain.exception.catalog.CatalogSubjectNotFoundException;
import com.synaptixfit.domain.exception.catalog.CenterNotFoundException;
import com.synaptixfit.domain.exception.catalog.DegreeNotFoundException;
import com.synaptixfit.domain.exception.catalog.UniversityNotFoundException;
import com.synaptixfit.domain.model.catalog.CatalogSubject;
import com.synaptixfit.domain.model.catalog.CatalogSubjectDetail;
import com.synaptixfit.domain.model.catalog.CatalogSubjectFilter;
import com.synaptixfit.domain.model.catalog.Center;
import com.synaptixfit.domain.model.catalog.Degree;
import com.synaptixfit.domain.model.catalog.University;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.catalog.AcademicCatalogPort;
import java.util.List;
import java.util.UUID;

/** Navegación de solo lectura por el catálogo académico. Un padre inexistente responde 404. */
public class CatalogService implements ListUniversitiesUseCase, GetUniversityUseCase, ListCentersUseCase,
        ListDegreesUseCase, GetDegreeUseCase, SearchCatalogSubjectsUseCase, GetCatalogSubjectUseCase {

    private final AcademicCatalogPort catalog;

    public CatalogService(AcademicCatalogPort catalog) {
        this.catalog = catalog;
    }

    @Override
    public List<University> listUniversities(String query) {
        return catalog.findUniversities(blankToNull(query));
    }

    @Override
    public University getUniversity(UUID universityId) {
        return catalog.findUniversity(universityId).orElseThrow(() -> new UniversityNotFoundException(universityId));
    }

    @Override
    public List<Center> listCenters(UUID universityId) {
        getUniversity(universityId);
        return catalog.findCentersByUniversity(universityId);
    }

    @Override
    public List<Degree> listDegreesByUniversity(UUID universityId, String query) {
        getUniversity(universityId);
        return catalog.findDegreesByUniversity(universityId, blankToNull(query));
    }

    @Override
    public List<Degree> listDegreesByCenter(UUID centerId) {
        catalog.findCenter(centerId).orElseThrow(() -> new CenterNotFoundException(centerId));
        return catalog.findDegreesByCenter(centerId);
    }

    @Override
    public Degree getDegree(UUID degreeId) {
        return catalog.findDegree(degreeId).orElseThrow(() -> new DegreeNotFoundException(degreeId));
    }

    @Override
    public PageResult<CatalogSubject> searchSubjects(UUID degreeId, CatalogSubjectFilter filter, PageRequest page) {
        getDegree(degreeId);
        return catalog.findSubjects(List.of(degreeId), filter == null ? CatalogSubjectFilter.none() : filter, page);
    }

    @Override
    public CatalogSubjectDetail getSubject(UUID subjectId) {
        return catalog.findSubjectDetail(subjectId).orElseThrow(() -> new CatalogSubjectNotFoundException(subjectId));
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.strip();
    }
}
