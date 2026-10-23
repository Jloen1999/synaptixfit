package com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto;

import com.synaptixfit.domain.model.catalog.UserCatalogSubject;
import java.util.UUID;

/**
 * Asignatura del catálogo de una carrera del usuario. {@code userSubjectId} es la asignatura propia
 * creada a partir de ella (nulo si no existe) y {@code active} indica que existe y no está archivada.
 */
public record UserCatalogSubjectResponse(CatalogSubjectResponse subject, UUID userSubjectId, boolean active) {

    public static UserCatalogSubjectResponse from(UserCatalogSubject s) {
        return new UserCatalogSubjectResponse(CatalogSubjectResponse.from(s.subject()), s.userSubjectId(), s.active());
    }
}
