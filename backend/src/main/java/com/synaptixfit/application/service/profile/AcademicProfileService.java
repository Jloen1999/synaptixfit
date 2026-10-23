package com.synaptixfit.application.service.profile;

import com.synaptixfit.application.port.input.profile.GetAcademicProfileUseCase;
import com.synaptixfit.application.port.input.profile.SaveAcademicProfileUseCase;
import com.synaptixfit.application.port.input.profile.UpdateAcademicProfileUseCase;
import com.synaptixfit.domain.exception.catalog.DegreeNotFoundException;
import com.synaptixfit.domain.exception.profile.AcademicProfileNotFoundException;
import com.synaptixfit.domain.model.catalog.Degree;
import com.synaptixfit.domain.model.profile.AcademicProfile;
import com.synaptixfit.domain.model.profile.StudyModality;
import com.synaptixfit.domain.port.output.catalog.AcademicCatalogPort;
import com.synaptixfit.domain.port.output.catalog.UserDegreeRepositoryPort;
import com.synaptixfit.domain.port.output.profile.AcademicProfileRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;

/**
 * Perfil académico. Cuando el cliente elige la carrera del catálogo ({@code degreeId}) se guardan
 * los nombres canónicos de universidad y carrera y se vincula la carrera (en el sistema antiguo
 * se mezclaban el id de la universidad y el nombre de la carrera en las mismas columnas de texto).
 */
public class AcademicProfileService implements GetAcademicProfileUseCase, SaveAcademicProfileUseCase,
        UpdateAcademicProfileUseCase {

    private final AcademicProfileRepositoryPort profiles;
    private final AcademicCatalogPort catalog;
    private final UserDegreeRepositoryPort userDegrees;
    private final Clock clock;

    public AcademicProfileService(AcademicProfileRepositoryPort profiles, AcademicCatalogPort catalog,
                                  UserDegreeRepositoryPort userDegrees, Clock clock) {
        this.profiles = profiles;
        this.catalog = catalog;
        this.userDegrees = userDegrees;
        this.clock = clock;
    }

    @Override
    public AcademicProfile getAcademicProfile(UUID userId) {
        return profiles.findByUserId(userId).orElseThrow(() -> new AcademicProfileNotFoundException(userId));
    }

    @Override
    public AcademicProfile saveAcademicProfile(SaveAcademicProfileUseCase.Command c) {
        Instant now = clock.instant();
        AcademicProfile profile = profiles.findByUserId(c.userId())
                .orElseGet(() -> AcademicProfile.createDefault(c.userId(), now));
        String university = c.university();
        String degree = c.degree();
        if (c.degreeId() != null) {
            Degree selected = resolveAndLink(c.userId(), c.degreeId(), now);
            university = selected.universityName();
            degree = selected.name();
        }
        profile.changeUniversity(university);
        profile.changeDegree(degree);
        profile.changeSemester(c.semester() != null ? c.semester() : AcademicProfile.DEFAULT_SEMESTER);
        profile.changeModality(c.modality() != null ? c.modality() : StudyModality.IN_PERSON);
        profile.changeSemesterCredits(c.semesterCredits() != null ? c.semesterCredits() : AcademicProfile.DEFAULT_CREDITS);
        profile.changeWeeklyStudyHoursGoal(c.weeklyStudyHoursGoal() != null
                ? c.weeklyStudyHoursGoal() : AcademicProfile.DEFAULT_WEEKLY_HOURS);
        profile.changeTargetGpa(c.targetGpa());
        profile.changeClassDates(c.classesStartDate(), c.classesEndDate());
        profile.touch(now);
        return profiles.save(profile);
    }

    @Override
    public AcademicProfile updateAcademicProfile(UpdateAcademicProfileUseCase.Command c) {
        Instant now = clock.instant();
        AcademicProfile profile = profiles.findByUserId(c.userId())
                .orElseGet(() -> AcademicProfile.createDefault(c.userId(), now));
        if (c.degreeId() != null) {
            Degree selected = resolveAndLink(c.userId(), c.degreeId(), now);
            profile.changeUniversity(selected.universityName());
            profile.changeDegree(selected.name());
        } else {
            if (c.university() != null) {
                profile.changeUniversity(c.university());
            }
            if (c.degree() != null) {
                profile.changeDegree(c.degree());
            }
        }
        if (c.semester() != null) {
            profile.changeSemester(c.semester());
        }
        if (c.modality() != null) {
            profile.changeModality(c.modality());
        }
        if (c.semesterCredits() != null) {
            profile.changeSemesterCredits(c.semesterCredits());
        }
        if (c.weeklyStudyHoursGoal() != null) {
            profile.changeWeeklyStudyHoursGoal(c.weeklyStudyHoursGoal());
        }
        if (c.targetGpa() != null) {
            profile.changeTargetGpa(c.targetGpa());
        }
        if (c.classesStartDate() != null || c.classesEndDate() != null) {
            profile.changeClassDates(
                    c.classesStartDate() != null ? c.classesStartDate() : profile.classesStartDate(),
                    c.classesEndDate() != null ? c.classesEndDate() : profile.classesEndDate());
        }
        profile.touch(now);
        return profiles.save(profile);
    }

    private Degree resolveAndLink(UUID userId, UUID degreeId, Instant now) {
        Degree degree = catalog.findDegree(degreeId).orElseThrow(() -> new DegreeNotFoundException(degreeId));
        if (!userDegrees.exists(userId, degreeId)) {
            userDegrees.link(userId, degreeId, now);
        }
        return degree;
    }
}
