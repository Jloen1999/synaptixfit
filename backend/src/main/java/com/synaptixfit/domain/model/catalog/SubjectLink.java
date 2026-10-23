package com.synaptixfit.domain.model.catalog;

import java.util.UUID;

/** Asignatura propia del usuario creada a partir de una del catálogo (lectura del módulo académico). */
public record SubjectLink(UUID subjectId, boolean archived) {
}
