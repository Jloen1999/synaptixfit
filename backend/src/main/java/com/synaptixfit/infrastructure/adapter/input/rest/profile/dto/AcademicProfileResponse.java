package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

import com.synaptixfit.domain.model.profile.AcademicProfile;
import com.synaptixfit.domain.model.profile.StudyModality;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Perfil académico. {@code hasSemesterDates} = fechas de inicio y fin de clases informadas. */
public record AcademicProfileResponse(UUID id, String university, String degree, int semester,
                                      StudyModality modality, int semesterCredits, int weeklyStudyHoursGoal,
                                      Double targetGpa, LocalDate classesStartDate, LocalDate classesEndDate,
                                      boolean hasSemesterDates, Instant createdAt, Instant updatedAt) {

    public static AcademicProfileResponse from(AcademicProfile p) {
        return new AcademicProfileResponse(p.id(), p.university(), p.degree(), p.semester(), p.modality(),
                p.semesterCredits(), p.weeklyStudyHoursGoal(), p.targetGpa(), p.classesStartDate(),
                p.classesEndDate(), p.hasSemesterDates(), p.createdAt(), p.updatedAt());
    }
}
