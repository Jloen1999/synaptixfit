package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.UUID;

/** Lista paginada de apuntes propios con filtros opcionales. */
public interface ListNotesUseCase {

    record Query(UUID userId, UUID subjectId, boolean quickOnly, boolean unassignedOnly, PageRequest page) {}

    PageResult<Note> listNotes(Query query);
}
