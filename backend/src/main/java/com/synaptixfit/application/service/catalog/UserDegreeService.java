package com.synaptixfit.application.service.catalog;

import com.synaptixfit.application.port.input.catalog.LinkDegreeUseCase;
import com.synaptixfit.application.port.input.catalog.ListMyCatalogSubjectsUseCase;
import com.synaptixfit.application.port.input.catalog.ListMyDegreesUseCase;
import com.synaptixfit.application.port.input.catalog.UnlinkDegreeUseCase;
import com.synaptixfit.domain.exception.catalog.DegreeNotFoundException;
import com.synaptixfit.domain.model.catalog.CatalogSubject;
import com.synaptixfit.domain.model.catalog.CatalogSubjectFilter;
import com.synaptixfit.domain.model.catalog.Degree;
import com.synaptixfit.domain.model.catalog.SubjectLink;
import com.synaptixfit.domain.model.catalog.UserCatalogSubject;
import com.synaptixfit.domain.model.catalog.UserDegree;
import com.synaptixfit.domain.model.catalog.UserDegreeLink;
import com.synaptixfit.domain.model.profile.AcademicProfile;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.catalog.AcademicCatalogPort;
import com.synaptixfit.domain.port.output.catalog.UserDegreeRepositoryPort;
import com.synaptixfit.domain.port.output.catalog.UserSubjectLinksPort;
import com.synaptixfit.domain.port.output.profile.AcademicProfileRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Carreras vinculadas por el usuario y su plan de estudios para el selector de asignaturas. */
public class UserDegreeService implements ListMyDegreesUseCase, LinkDegreeUseCase, UnlinkDegreeUseCase,
        ListMyCatalogSubjectsUseCase {

    private final UserDegreeRepositoryPort userDegrees;
    private final AcademicCatalogPort catalog;
    private final AcademicProfileRepositoryPort academicProfiles;
    private final UserSubjectLinksPort subjectLinks;
    private final Clock clock;

    public UserDegreeService(UserDegreeRepositoryPort userDegrees, AcademicCatalogPort catalog,
                             AcademicProfileRepositoryPort academicProfiles, UserSubjectLinksPort subjectLinks,
                             Clock clock) {
        this.userDegrees = userDegrees;
        this.catalog = catalog;
        this.academicProfiles = academicProfiles;
        this.subjectLinks = subjectLinks;
        this.clock = clock;
    }

    @Override
    public List<UserDegree> listMyDegrees(UUID userId) {
        List<UserDegreeLink> links = userDegrees.findByUser(userId);
        if (links.isEmpty()) {
            return List.of();
        }
        Map<UUID, Degree> degrees = catalog.findDegreesByIds(links.stream().map(UserDegreeLink::degreeId).toList())
                .stream().collect(Collectors.toMap(Degree::id, Function.identity()));
        return links.stream()
                .filter(link -> degrees.containsKey(link.degreeId()))
                .map(link -> new UserDegree(degrees.get(link.degreeId()), link.linkedAt()))
                .toList();
    }

    @Override
    public UserDegree linkDegree(UUID userId, UUID degreeId) {
        Degree degree = catalog.findDegree(degreeId).orElseThrow(() -> new DegreeNotFoundException(degreeId));
        Instant linkedAt = userDegrees.findByUser(userId).stream()
                .filter(link -> link.degreeId().equals(degreeId))
                .map(UserDegreeLink::linkedAt)
                .findFirst()
                .orElse(null);
        if (linkedAt == null) {
            linkedAt = clock.instant();
            userDegrees.link(userId, degreeId, linkedAt);
        }
        return new UserDegree(degree, linkedAt);
    }

    @Override
    public void unlinkDegree(UUID userId, UUID degreeId) {
        userDegrees.unlink(userId, degreeId);
    }

    @Override
    public PageResult<UserCatalogSubject> listMyCatalogSubjects(UUID userId, CatalogSubjectFilter filter,
                                                                PageRequest page) {
        List<UUID> degreeIds = effectiveDegreeIds(userId);
        if (degreeIds.isEmpty()) {
            return new PageResult<>(List.of(), page.page(), page.size(), 0);
        }
        PageResult<CatalogSubject> subjects = catalog.findSubjects(degreeIds,
                filter == null ? CatalogSubjectFilter.none() : filter, page);
        Map<UUID, SubjectLink> links = subjectLinks.findByCatalogSubjects(userId,
                subjects.items().stream().map(CatalogSubject::id).toList());
        return subjects.map(subject -> {
            SubjectLink link = links.get(subject.id());
            return link == null
                    ? new UserCatalogSubject(subject, null, false)
                    : new UserCatalogSubject(subject, link.subjectId(), !link.archived());
        });
    }

    /**
     * Carreras vinculadas; si no hay ninguna (datos heredados que solo guardaban el nombre en el
     * perfil académico), la carrera del catálogo cuyo nombre coincide sin ambigüedad.
     */
    private List<UUID> effectiveDegreeIds(UUID userId) {
        List<UUID> linked = userDegrees.findByUser(userId).stream().map(UserDegreeLink::degreeId).toList();
        if (!linked.isEmpty()) {
            return linked;
        }
        String degreeName = academicProfiles.findByUserId(userId).map(AcademicProfile::degree).orElse(null);
        if (degreeName == null) {
            return List.of();
        }
        List<Degree> matches = catalog.findDegreesByName(degreeName);
        return matches.size() == 1 ? List.of(matches.get(0).id()) : List.of();
    }
}
