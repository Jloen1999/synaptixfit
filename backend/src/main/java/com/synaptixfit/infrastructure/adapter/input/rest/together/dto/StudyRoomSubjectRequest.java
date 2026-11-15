package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import java.util.UUID;

/** Asignatura propia con la que cuentan las rondas de la sala; nula para ninguna. */
public record StudyRoomSubjectRequest(UUID subjectId) {
}
