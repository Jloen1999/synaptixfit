package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

import com.synaptixfit.domain.model.profile.StudyModality;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Perfil académico. En PUT los nulos toman el valor por defecto o se borran; en PATCH no cambian.
 * Si llega {@code degreeId}, universidad y carrera se toman del catálogo y la carrera se vincula.
 */
public record AcademicProfileRequest(
        @Size(max = 200) String university,
        @Size(max = 200) String degree,
        UUID degreeId,
        @Min(1) @Max(20) Integer semester,
        StudyModality modality,
        @Min(1) @Max(60) Integer semesterCredits,
        @Min(0) @Max(80) Integer weeklyStudyHoursGoal,
        @DecimalMin("0") @DecimalMax("5") Double targetGpa,
        LocalDate classesStartDate,
        LocalDate classesEndDate) {
}
