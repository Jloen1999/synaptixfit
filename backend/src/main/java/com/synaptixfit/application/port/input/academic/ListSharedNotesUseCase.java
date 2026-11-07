package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SharedNoteSummary;
import com.synaptixfit.domain.model.shared.AudienceScope;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.UUID;

/**
 * Resúmenes de los apuntes de otros usuarios que el usuario puede leer (regla de
 * {@code EffectiveVisibility}), por ámbito (amigos o comunidad), autor y asignatura del catálogo.
 */
public interface ListSharedNotesUseCase {

    /**
     * {@code scope} nulo equivale a {@link AudienceScope#ALL}; {@code authorId}, {@code catalogSubjectId} y
     * {@code search} (título, asignatura o autor, sin distinguir tildes; ADR 0036) son opcionales.
     */
    record Query(UUID userId, AudienceScope scope, UUID authorId, UUID catalogSubjectId, PageRequest page,
                 String search) {

        public Query(UUID userId, AudienceScope scope, UUID authorId, UUID catalogSubjectId, PageRequest page) {
            this(userId, scope, authorId, catalogSubjectId, page, null);
        }
    }

    PageResult<SharedNoteSummary> listSharedNotes(Query query);
}
