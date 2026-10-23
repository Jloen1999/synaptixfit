package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.challenge.ChallengeLink;
import com.synaptixfit.domain.model.challenge.LinkType;
import java.util.UUID;

/** Construye el vínculo a partir de los dos campos de la petición, que van juntos. */
final class Links {

    private Links() {
    }

    static ChallengeLink of(LinkType type, UUID id) {
        if (type == null && id == null) {
            return null;
        }
        if (type == null || id == null) {
            throw new FieldValidationException(type == null ? "linkedEntityType" : "linkedEntityId", "REQUIRED",
                    "linkedEntityType and linkedEntityId go together");
        }
        return new ChallengeLink(type, id);
    }
}
