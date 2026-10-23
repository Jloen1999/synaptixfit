package com.synaptixfit.domain.model.challenge;

import java.util.Collection;

/** Recuento de retos del usuario por estado. */
public record ChallengeSummary(long active, long completed, long expired) {

    /** Cuenta los estados ya resueltos con {@link Challenge#statusOf}. */
    public static ChallengeSummary of(Collection<ChallengeStatus> statuses) {
        return new ChallengeSummary(
                statuses.stream().filter(s -> s == ChallengeStatus.ACTIVE).count(),
                statuses.stream().filter(s -> s == ChallengeStatus.COMPLETED).count(),
                statuses.stream().filter(s -> s == ChallengeStatus.EXPIRED).count());
    }

    public long total() {
        return active + completed + expired;
    }
}
