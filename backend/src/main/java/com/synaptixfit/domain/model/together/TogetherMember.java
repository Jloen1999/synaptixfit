package com.synaptixfit.domain.model.together;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.UUID;

/** Una persona en un reto con amigos o en un «Entrenamos juntos», con su situación y cuándo cambió. */
public record TogetherMember(UUID userId, MemberStatus status, Instant updatedAt) {

    public TogetherMember {
        Guard.notNull(userId, "userId");
        Guard.notNull(status, "status");
        Guard.notNull(updatedAt, "updatedAt");
    }

    public boolean joined() {
        return status == MemberStatus.JOINED;
    }

    TogetherMember with(MemberStatus newStatus, Instant now) {
        return new TogetherMember(userId, newStatus, now);
    }
}
