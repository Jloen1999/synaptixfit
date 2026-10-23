package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Guard;
import java.util.UUID;

/** Referencia a una fuente de estudio (apunte o archivo). */
public record StudySourceRef(StudySourceType type, UUID id) {

    public StudySourceRef {
        Guard.notNull(type, "type");
        Guard.notNull(id, "id");
    }
}
