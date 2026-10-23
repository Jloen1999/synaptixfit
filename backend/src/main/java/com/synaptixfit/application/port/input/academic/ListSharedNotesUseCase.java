package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SharedNote;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.UUID;

/** Apuntes de otros usuarios visibles para el usuario (públicos o de amigos). */
public interface ListSharedNotesUseCase {

    PageResult<SharedNote> listSharedNotes(UUID userId, PageRequest page);
}
