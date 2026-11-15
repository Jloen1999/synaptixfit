package com.synaptixfit.domain.model.social;

import com.synaptixfit.domain.exception.social.FriendshipSelfTargetException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.UUID;

/**
 * Denuncia de una persona desde lo compartido con amigos (ADR 0044). Como allí no hay texto libre, se denuncia a la
 * persona y el lugar donde pasó; la revisa la administración en la cola de moderación.
 */
public record UserReport(UUID id, UUID reporterId, UUID reportedId, UserReportContext context, Instant createdAt) {

    public UserReport {
        Guard.notNull(id, "id");
        Guard.notNull(reporterId, "reporterId");
        Guard.notNull(reportedId, "reportedId");
        Guard.notNull(context, "context");
        Guard.notNull(createdAt, "createdAt");
        if (reporterId.equals(reportedId)) {
            throw new FriendshipSelfTargetException(reporterId);
        }
    }

    public static UserReport of(UUID reporterId, UUID reportedId, UserReportContext context, Instant now) {
        return new UserReport(UUID.randomUUID(), reporterId, reportedId, context, now);
    }
}
