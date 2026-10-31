package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.notification;

import com.synaptixfit.domain.model.notification.WeeklyEmailSubscription;
import com.synaptixfit.domain.port.output.notification.WeeklyEmailSubscriptionRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.notification.WeeklyEmailSubscriptionEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.notification.WeeklyEmailSubscriptionJpaRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link WeeklyEmailSubscriptionRepositoryPort} con JPA (estado en minúsculas en la BD). */
@Repository
public class WeeklyEmailSubscriptionPersistenceAdapter implements WeeklyEmailSubscriptionRepositoryPort {

    private static final String ACTIVE = "activa";
    private static final String PENDING = "pendiente";

    private final WeeklyEmailSubscriptionJpaRepository repository;

    public WeeklyEmailSubscriptionPersistenceAdapter(WeeklyEmailSubscriptionJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public WeeklyEmailSubscription save(WeeklyEmailSubscription s) {
        WeeklyEmailSubscriptionEntity e = repository.findById(s.userId())
                .orElseGet(WeeklyEmailSubscriptionEntity::new);
        e.setUsuarioId(s.userId());
        e.setEstado(s.isActive() ? ACTIVE : PENDING);
        e.setIdioma(s.language());
        e.setTokenConfirmacionHash(s.confirmTokenHash());
        e.setTokenBaja(s.unsubscribeToken());
        e.setUltimaSemanaEnviada(s.lastSentWeek());
        e.setActualizadoEn(s.updatedAt());
        repository.save(e);
        return s;
    }

    @Override
    public Optional<WeeklyEmailSubscription> findByUser(UUID userId) {
        return repository.findById(userId).map(WeeklyEmailSubscriptionPersistenceAdapter::toDomain);
    }

    @Override
    public Optional<WeeklyEmailSubscription> findByConfirmTokenHash(String tokenHash) {
        return repository.findByTokenConfirmacionHash(tokenHash)
                .map(WeeklyEmailSubscriptionPersistenceAdapter::toDomain);
    }

    @Override
    public Optional<WeeklyEmailSubscription> findByUnsubscribeToken(String token) {
        return repository.findByTokenBaja(token).map(WeeklyEmailSubscriptionPersistenceAdapter::toDomain);
    }

    @Override
    public List<WeeklyEmailSubscription> findActive() {
        return repository.findByEstado(ACTIVE).stream()
                .map(WeeklyEmailSubscriptionPersistenceAdapter::toDomain).toList();
    }

    @Override
    public void deleteByUser(UUID userId) {
        repository.findById(userId).ifPresent(repository::delete);
    }

    @Override
    public void markSent(UUID userId, LocalDate weekStart, Instant now) {
        repository.markSent(userId, weekStart, now, ACTIVE);
    }

    private static WeeklyEmailSubscription toDomain(WeeklyEmailSubscriptionEntity e) {
        return new WeeklyEmailSubscription(e.getUsuarioId(),
                ACTIVE.equals(e.getEstado()) ? WeeklyEmailSubscription.Status.ACTIVE
                        : WeeklyEmailSubscription.Status.PENDING,
                e.getIdioma(), e.getTokenConfirmacionHash(), e.getTokenBaja(), e.getUltimaSemanaEnviada(),
                e.getActualizadoEn());
    }
}
