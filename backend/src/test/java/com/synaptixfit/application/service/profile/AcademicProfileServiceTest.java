package com.synaptixfit.application.service.profile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.profile.SaveAcademicProfileUseCase;
import com.synaptixfit.application.port.input.profile.UpdateAcademicProfileUseCase;
import com.synaptixfit.domain.exception.catalog.DegreeNotFoundException;
import com.synaptixfit.domain.exception.profile.AcademicProfileNotFoundException;
import com.synaptixfit.domain.exception.profile.InvalidClassDatesException;
import com.synaptixfit.domain.model.catalog.Degree;
import com.synaptixfit.domain.model.profile.AcademicProfile;
import com.synaptixfit.domain.model.profile.StudyModality;
import com.synaptixfit.support.ProfileTestDoubles;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class AcademicProfileServiceTest {

    private final UUID userId = UUID.randomUUID();
    private final ProfileTestDoubles.Academic profiles = new ProfileTestDoubles.Academic();
    private final ProfileTestDoubles.Catalog catalog = new ProfileTestDoubles.Catalog();
    private final ProfileTestDoubles.UserDegrees userDegrees = new ProfileTestDoubles.UserDegrees();
    private final AcademicProfileService service = new AcademicProfileService(profiles, catalog, userDegrees,
            Clock.fixed(Instant.parse("2026-09-01T08:00:00Z"), ZoneOffset.UTC));

    private UpdateAcademicProfileUseCase.Command patch(UUID degreeId, LocalDate start, LocalDate end) {
        return new UpdateAcademicProfileUseCase.Command(userId, null, null, degreeId, null, null, null, null, null,
                start, end);
    }

    @Test
    void getWithoutProfileIsNotFound() {
        assertThatThrownBy(() -> service.getAcademicProfile(userId))
                .isInstanceOf(AcademicProfileNotFoundException.class)
                .extracting("code").isEqualTo("PROFILE_ACADEMIC_NOT_FOUND");
    }

    @Test
    void patchCreatesProfileWithDefaultsAndSemesterDates() {
        AcademicProfile p = service.updateAcademicProfile(
                patch(null, LocalDate.parse("2026-09-15"), LocalDate.parse("2027-01-20")));

        assertThat(p.semester()).isEqualTo(1);
        assertThat(p.modality()).isEqualTo(StudyModality.IN_PERSON);
        assertThat(p.semesterCredits()).isEqualTo(20);
        assertThat(p.weeklyStudyHoursGoal()).isEqualTo(14);
        assertThat(p.hasSemesterDates()).isTrue();
    }

    @Test
    void patchKeepsTheOtherDateWhenOnlyOneChanges() {
        service.updateAcademicProfile(patch(null, LocalDate.parse("2026-09-15"), LocalDate.parse("2027-01-20")));

        assertThatThrownBy(() -> service.updateAcademicProfile(patch(null, LocalDate.parse("2027-02-01"), null)))
                .isInstanceOf(InvalidClassDatesException.class)
                .extracting("code").isEqualTo("PROFILE_INVALID_CLASS_DATES");

        AcademicProfile p = service.updateAcademicProfile(patch(null, null, LocalDate.parse("2027-02-10")));
        assertThat(p.classesStartDate()).isEqualTo(LocalDate.parse("2026-09-15"));
        assertThat(p.classesEndDate()).isEqualTo(LocalDate.parse("2027-02-10"));
    }

    @Test
    void choosingDegreeFromCatalogStoresCanonicalNamesAndLinksIt() {
        Degree degree = catalog.addDegree("Grado en Ingeniería Informática");

        AcademicProfile p = service.saveAcademicProfile(new SaveAcademicProfileUseCase.Command(userId, "ignored",
                "ignored", degree.id(), 3, StudyModality.HYBRID, 30, 20, 4.2, null, null));

        assertThat(p.university()).isEqualTo("Universidad de Granada");
        assertThat(p.degree()).isEqualTo("Grado en Ingeniería Informática");
        assertThat(p.semester()).isEqualTo(3);
        assertThat(p.targetGpa()).isEqualTo(4.2);
        assertThat(userDegrees.exists(userId, degree.id())).isTrue();

        service.updateAcademicProfile(patch(degree.id(), null, null));
        assertThat(userDegrees.rows).hasSize(1);
    }

    @Test
    void putReplacesOptionalValuesWithDefaults() {
        service.saveAcademicProfile(new SaveAcademicProfileUseCase.Command(userId, "UGR", "Informática", null, 5,
                StudyModality.ONLINE, 40, 30, 3.5, LocalDate.parse("2026-09-15"), LocalDate.parse("2027-01-20")));

        AcademicProfile p = service.saveAcademicProfile(new SaveAcademicProfileUseCase.Command(userId, "UGR", null,
                null, null, null, null, null, null, null, null));

        assertThat(p.degree()).isNull();
        assertThat(p.semester()).isEqualTo(1);
        assertThat(p.targetGpa()).isNull();
        assertThat(p.hasSemesterDates()).isFalse();
        assertThat(profiles.byUser).hasSize(1);
    }

    @Test
    void unknownDegreeIsNotFound() {
        assertThatThrownBy(() -> service.updateAcademicProfile(patch(UUID.randomUUID(), null, null)))
                .isInstanceOf(DegreeNotFoundException.class)
                .extracting("code").isEqualTo("CATALOG_DEGREE_NOT_FOUND");
        assertThat(profiles.byUser).isEmpty();
    }
}
