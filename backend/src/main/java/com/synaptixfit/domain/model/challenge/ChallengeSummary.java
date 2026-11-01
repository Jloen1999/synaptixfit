package com.synaptixfit.domain.model.challenge;

import java.util.Collection;

/**
 * Recuento de retos del usuario por estado. {@code active} cuenta los retos abiertos (en curso y por
 * empezar) para que los clientes anteriores sigan sumando igual; {@code upcoming} desglosa los segundos.
 */
public record ChallengeSummary(long active, long completed, long expired, long upcoming) {

    /** Cuenta los estados ya resueltos con {@link Challenge#statusOf}. */
    public static ChallengeSummary of(Collection<ChallengeStatus> statuses) {
        long upcoming = statuses.stream().filter(s -> s == ChallengeStatus.UPCOMING).count();
        return new ChallengeSummary(
                statuses.stream().filter(s -> s == ChallengeStatus.ACTIVE).count() + upcoming,
                statuses.stream().filter(s -> s == ChallengeStatus.COMPLETED).count(),
                statuses.stream().filter(s -> s == ChallengeStatus.EXPIRED).count(),
                upcoming);
    }

    public long total() {
        return active + completed + expired;
    }
}
