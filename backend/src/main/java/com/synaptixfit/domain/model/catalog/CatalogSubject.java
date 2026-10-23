package com.synaptixfit.domain.model.catalog;

import java.util.UUID;

/**
 * Asignatura del plan de estudios de una carrera. {@code semester} es el semestre dentro del
 * curso (0 = sin semestre fijo, típico de optativas); {@code character} es el carácter tal como
 * figura en el plan (Formación básica, Obligatoria, Optativa…).
 */
public record CatalogSubject(UUID id, UUID degreeId, String name, Integer course, Integer semester, String character,
                             Double credits, Integer hours, String department, String language,
                             String teachingGuideUrl) {
}
