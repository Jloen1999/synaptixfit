package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/** Lo elegido de la propuesta: carrera (opcional), asignaturas del catálogo y asignaturas propias. */
public record ApplyEnrollmentRequest(UUID degreeId, @Size(max = 40) List<UUID> catalogSubjectIds,
                                     @Size(max = 40) List<@Valid CustomSubject> customSubjects) {

    public record CustomSubject(@NotBlank @Size(max = 200) String name, @Size(max = 40) String code,
                                Integer credits) {
    }
}
