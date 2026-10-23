package com.synaptixfit.domain.model.catalog;

import java.util.UUID;

/**
 * Asignatura del catálogo de una carrera del usuario, con su asignatura propia si ya la creó.
 * {@code active} = existe y no está archivada.
 */
public record UserCatalogSubject(CatalogSubject subject, UUID userSubjectId, boolean active) {
}
