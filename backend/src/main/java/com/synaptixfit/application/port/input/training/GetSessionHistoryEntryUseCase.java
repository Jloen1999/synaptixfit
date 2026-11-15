package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.SessionHistoryEntry;
import java.util.UUID;

/**
 * Una sesión propia como en el historial (nombre, foto de su tarjeta y récords): la usa el detalle abierto sin pasar
 * por el historial (aviso, Inicio, enlace), para que la foto la elija el servidor con {@code SessionLabel.withCover}.
 */
public interface GetSessionHistoryEntryUseCase {

    /** Lanza SessionNotFoundException si la sesión no existe o no es del usuario. */
    SessionHistoryEntry historyEntry(UUID userId, UUID sessionId);
}
