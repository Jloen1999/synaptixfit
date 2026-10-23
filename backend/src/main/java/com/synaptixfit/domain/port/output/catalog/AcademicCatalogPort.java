package com.synaptixfit.domain.port.output.catalog;

import com.synaptixfit.domain.model.catalog.CatalogSubject;
import com.synaptixfit.domain.model.catalog.CatalogSubjectDetail;
import com.synaptixfit.domain.model.catalog.CatalogSubjectFilter;
import com.synaptixfit.domain.model.catalog.Center;
import com.synaptixfit.domain.model.catalog.Degree;
import com.synaptixfit.domain.model.catalog.University;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Lectura del catálogo académico (universidades, centros, carreras y planes de estudio). */
public interface AcademicCatalogPort {

    /** Universidades ordenadas por nombre; {@code query} filtra por nombre (opcional). */
    List<University> findUniversities(String query);

    Optional<University> findUniversity(UUID id);

    List<Center> findCentersByUniversity(UUID universityId);

    Optional<Center> findCenter(UUID id);

    /** Carreras de todos los centros de la universidad, ordenadas por nombre. */
    List<Degree> findDegreesByUniversity(UUID universityId, String query);

    List<Degree> findDegreesByCenter(UUID centerId);

    Optional<Degree> findDegree(UUID id);

    List<Degree> findDegreesByIds(Collection<UUID> ids);

    /** Carreras cuyo nombre coincide exactamente (sin distinguir mayúsculas). */
    List<Degree> findDegreesByName(String name);

    /** Asignaturas de las carreras indicadas, ordenadas por curso, semestre y nombre. */
    PageResult<CatalogSubject> findSubjects(Collection<UUID> degreeIds, CatalogSubjectFilter filter, PageRequest page);

    Optional<CatalogSubjectDetail> findSubjectDetail(UUID subjectId);
}
