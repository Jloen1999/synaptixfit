package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.UserReportContext;
import java.util.UUID;

/** Denuncia a una persona desde lo compartido con amigos (ADR 0044); va a la cola de moderación. */
public interface ReportUserUseCase {

    void reportUser(UUID reporterId, UUID reportedId, UserReportContext context);
}
