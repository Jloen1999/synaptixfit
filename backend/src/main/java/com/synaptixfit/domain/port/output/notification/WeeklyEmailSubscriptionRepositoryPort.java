package com.synaptixfit.domain.port.output.notification;

import com.synaptixfit.domain.model.notification.WeeklyEmailSubscription;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de las suscripciones al resumen semanal por correo (una por usuario). */
public interface WeeklyEmailSubscriptionRepositoryPort {

    WeeklyEmailSubscription save(WeeklyEmailSubscription subscription);

    Optional<WeeklyEmailSubscription> findByUser(UUID userId);

    Optional<WeeklyEmailSubscription> findByConfirmTokenHash(String tokenHash);

    Optional<WeeklyEmailSubscription> findByUnsubscribeToken(String token);

    List<WeeklyEmailSubscription> findActive();

    void deleteByUser(UUID userId);

    /**
     * Apunta la semana enviada solo si la suscripción sigue activa (nunca la crea): quien se da de baja mientras
     * sale el envío no vuelve a quedar suscrito.
     */
    void markSent(UUID userId, LocalDate weekStart, Instant now);
}
