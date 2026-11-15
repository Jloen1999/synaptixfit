package com.synaptixfit.application.service.social;

import com.synaptixfit.application.port.input.social.ReportUserUseCase;
import com.synaptixfit.domain.exception.social.SocialUserNotFoundException;
import com.synaptixfit.domain.model.social.UserReport;
import com.synaptixfit.domain.model.social.UserReportContext;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.social.UserReportRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.util.UUID;

/**
 * Implementa {@link ReportUserUseCase} (ADR 0044): guarda la denuncia con {@link UserReportRepositoryPort} para la cola
 * de moderación. No bloquea por su cuenta: bloquear es otra acción de un toque al lado.
 */
public class UserReportService implements ReportUserUseCase {

    private final UserReportRepositoryPort reports;
    private final UserRepositoryPort users;
    private final Clock clock;

    public UserReportService(UserReportRepositoryPort reports, UserRepositoryPort users, Clock clock) {
        this.reports = reports;
        this.users = users;
        this.clock = clock;
    }

    @Override
    public void reportUser(UUID reporterId, UUID reportedId, UserReportContext context) {
        users.findById(reportedId).filter(User::isActive)
                .orElseThrow(() -> new SocialUserNotFoundException(reportedId));
        // Una denuncia sin revisar de la misma persona basta: repetirla no hace nada (no llena la cola).
        if (!reports.existsPending(reporterId, reportedId)) {
            reports.save(UserReport.of(reporterId, reportedId, context, clock.instant()));
        }
    }
}
