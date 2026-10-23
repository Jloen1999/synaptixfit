package com.synaptixfit.application.service.catalog;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.catalog.CatalogSubjectNotFoundException;
import com.synaptixfit.domain.exception.catalog.CenterNotFoundException;
import com.synaptixfit.domain.exception.catalog.DegreeNotFoundException;
import com.synaptixfit.domain.exception.catalog.UniversityNotFoundException;
import com.synaptixfit.domain.model.catalog.CatalogSubject;
import com.synaptixfit.domain.model.catalog.CatalogSubjectFilter;
import com.synaptixfit.domain.model.catalog.Degree;
import com.synaptixfit.domain.model.catalog.SubjectLink;
import com.synaptixfit.domain.model.catalog.UserCatalogSubject;
import com.synaptixfit.domain.model.catalog.UserDegree;
import com.synaptixfit.domain.model.profile.AcademicProfile;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.support.ProfileTestDoubles;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class CatalogServicesTest {

    private final Instant now = Instant.parse("2026-10-01T10:00:00Z");
    private final UUID userId = UUID.randomUUID();
    private final ProfileTestDoubles.Catalog catalog = new ProfileTestDoubles.Catalog();
    private final ProfileTestDoubles.UserDegrees userDegrees = new ProfileTestDoubles.UserDegrees();
    private final ProfileTestDoubles.Academic academic = new ProfileTestDoubles.Academic();
    private final ProfileTestDoubles.SubjectLinks links = new ProfileTestDoubles.SubjectLinks();
    private final CatalogService catalogService = new CatalogService(catalog);
    private final UserDegreeService userDegreeService = new UserDegreeService(userDegrees, catalog, academic, links,
            Clock.fixed(now, ZoneOffset.UTC));

    @Test
    void missingParentsAreNotFound() {
        assertThatThrownBy(() -> catalogService.listCenters(UUID.randomUUID()))
                .isInstanceOf(UniversityNotFoundException.class)
                .extracting("code").isEqualTo("CATALOG_UNIVERSITY_NOT_FOUND");
        assertThatThrownBy(() -> catalogService.listDegreesByCenter(UUID.randomUUID()))
                .isInstanceOf(CenterNotFoundException.class)
                .extracting("code").isEqualTo("CATALOG_CENTER_NOT_FOUND");
        assertThatThrownBy(() -> catalogService.searchSubjects(UUID.randomUUID(), CatalogSubjectFilter.none(),
                new PageRequest(0, 20)))
                .isInstanceOf(DegreeNotFoundException.class);
        assertThatThrownBy(() -> catalogService.getSubject(UUID.randomUUID()))
                .isInstanceOf(CatalogSubjectNotFoundException.class)
                .extracting("code").isEqualTo("CATALOG_SUBJECT_NOT_FOUND");
    }

    @Test
    void browsesTheCatalog() {
        Degree degree = catalog.addDegree("Grado en Ingeniería Informática");
        catalog.addSubject(degree, "Cálculo", 1, 1);
        catalog.addSubject(degree, "Redes", 2, 1);

        assertThat(catalogService.listCenters(catalog.university.id())).hasSize(1);
        assertThat(catalogService.listDegreesByUniversity(catalog.university.id(), " ")).hasSize(1);
        PageResult<CatalogSubject> page = catalogService.searchSubjects(degree.id(),
                new CatalogSubjectFilter(2, null, null, null), new PageRequest(0, 20));
        assertThat(page.items()).extracting(CatalogSubject::name).containsExactly("Redes");
    }

    @Test
    void linkingIsIdempotentAndUnlinkRemoves() {
        Degree degree = catalog.addDegree("Grado en Matemáticas");

        UserDegree first = userDegreeService.linkDegree(userId, degree.id());
        UserDegree second = userDegreeService.linkDegree(userId, degree.id());

        assertThat(first.linkedAt()).isEqualTo(now).isEqualTo(second.linkedAt());
        assertThat(userDegrees.rows).hasSize(1);
        assertThat(userDegreeService.listMyDegrees(userId)).hasSize(1);

        userDegreeService.unlinkDegree(userId, degree.id());
        userDegreeService.unlinkDegree(userId, degree.id());
        assertThat(userDegreeService.listMyDegrees(userId)).isEmpty();
    }

    @Test
    void linkingUnknownDegreeIsNotFound() {
        assertThatThrownBy(() -> userDegreeService.linkDegree(userId, UUID.randomUUID()))
                .isInstanceOf(DegreeNotFoundException.class);
    }

    @Test
    void myCatalogSubjectsMarkWhichOnesTheUserAlreadyHas() {
        Degree degree = catalog.addDegree("Grado en Ingeniería Informática");
        CatalogSubject calculus = catalog.addSubject(degree, "Cálculo", 1, 1);
        CatalogSubject networks = catalog.addSubject(degree, "Redes", 2, 1);
        CatalogSubject archived = catalog.addSubject(degree, "Física", 1, 2);
        UUID ownSubject = UUID.randomUUID();
        links.byCatalogId.put(calculus.id(), new SubjectLink(ownSubject, false));
        links.byCatalogId.put(archived.id(), new SubjectLink(UUID.randomUUID(), true));
        userDegreeService.linkDegree(userId, degree.id());

        PageResult<UserCatalogSubject> page = userDegreeService.listMyCatalogSubjects(userId,
                CatalogSubjectFilter.none(), new PageRequest(0, 20));

        assertThat(page.totalItems()).isEqualTo(3);
        assertThat(page.items()).filteredOn(s -> s.subject().id().equals(calculus.id())).singleElement()
                .satisfies(s -> {
                    assertThat(s.userSubjectId()).isEqualTo(ownSubject);
                    assertThat(s.active()).isTrue();
                });
        assertThat(page.items()).filteredOn(s -> s.subject().id().equals(networks.id())).singleElement()
                .satisfies(s -> assertThat(s.userSubjectId()).isNull());
        assertThat(page.items()).filteredOn(s -> s.subject().id().equals(archived.id())).singleElement()
                .satisfies(s -> assertThat(s.active()).isFalse());
    }

    @Test
    void myCatalogSubjectsFallBackToDegreeNameOfAcademicProfile() {
        Degree degree = catalog.addDegree("Grado en Ingeniería Informática");
        catalog.addSubject(degree, "Cálculo", 1, 1);
        AcademicProfile profile = AcademicProfile.createDefault(userId, now);

        assertThat(userDegreeService.listMyCatalogSubjects(userId, null, new PageRequest(0, 20)).items()).isEmpty();

        profile.changeDegree("grado en ingeniería informática");
        academic.save(profile);
        assertThat(userDegreeService.listMyCatalogSubjects(userId, null, new PageRequest(0, 20)).items()).hasSize(1);
    }
}
