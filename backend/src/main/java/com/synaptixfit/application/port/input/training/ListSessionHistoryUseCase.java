package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.SessionHistoryEntry;
import java.util.UUID;

/** Historial de sesiones completadas con su nombre (rutina y día) y los récords batidos. */
public interface ListSessionHistoryUseCase {

    PageResult<SessionHistoryEntry> listHistory(UUID userId, PageRequest page);
}
