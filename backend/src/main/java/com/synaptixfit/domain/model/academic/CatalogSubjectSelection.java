package com.synaptixfit.domain.model.academic;

import java.util.UUID;

/**
 * Asignatura del catálogo junto con la asignatura del usuario enlazada (si existe).
 * {@code selected} indica que está enlazada y no archivada.
 */
public record CatalogSubjectSelection(CatalogSubject catalogSubject, UUID subjectId, boolean selected) {
}
