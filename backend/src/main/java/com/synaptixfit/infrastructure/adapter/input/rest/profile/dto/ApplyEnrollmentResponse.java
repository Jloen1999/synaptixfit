package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

/** Resultado de añadir la matrícula: asignaturas añadidas y si se vinculó la carrera. */
public record ApplyEnrollmentResponse(int subjectsAdded, boolean degreeLinked) {
}
