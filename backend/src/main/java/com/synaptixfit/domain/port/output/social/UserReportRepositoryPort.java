package com.synaptixfit.domain.port.output.social;

import com.synaptixfit.domain.model.social.UserReport;
import java.util.UUID;

/** Denuncias de personas (tabla {@code denuncias_usuario}, ADR 0044). */
public interface UserReportRepositoryPort {

    void save(UserReport report);

    /** ¿Ya hay una denuncia sin revisar de {@code reporterId} a {@code reportedId}? */
    boolean existsPending(UUID reporterId, UUID reportedId);

    /** Quita la denuncia de la cola de moderación (al revisarla). */
    boolean delete(UUID id);
}
