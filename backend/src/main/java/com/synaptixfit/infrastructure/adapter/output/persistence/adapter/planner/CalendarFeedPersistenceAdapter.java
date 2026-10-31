package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.planner;

import com.synaptixfit.domain.model.planner.CalendarFeed;
import com.synaptixfit.domain.port.output.planner.CalendarFeedRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.CalendarFeedEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.planner.CalendarFeedJpaRepository;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link CalendarFeedRepositoryPort} con JPA (una fila por usuario: guardar sustituye). */
@Repository
public class CalendarFeedPersistenceAdapter implements CalendarFeedRepositoryPort {

    private final CalendarFeedJpaRepository repository;

    public CalendarFeedPersistenceAdapter(CalendarFeedJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public CalendarFeed save(CalendarFeed feed) {
        CalendarFeedEntity entity = repository.findById(feed.userId()).orElseGet(CalendarFeedEntity::new);
        entity.setUsuarioId(feed.userId());
        entity.setTokenHash(feed.tokenHash());
        entity.setCreadoEn(feed.createdAt());
        repository.saveAndFlush(entity);
        return feed;
    }

    @Override
    public Optional<CalendarFeed> findByUser(UUID userId) {
        return repository.findById(userId).map(CalendarFeedPersistenceAdapter::toDomain);
    }

    @Override
    public Optional<CalendarFeed> findByTokenHash(String tokenHash) {
        return repository.findByTokenHash(tokenHash).map(CalendarFeedPersistenceAdapter::toDomain);
    }

    @Override
    public void deleteByUser(UUID userId) {
        repository.findById(userId).ifPresent(repository::delete);
    }

    private static CalendarFeed toDomain(CalendarFeedEntity e) {
        return new CalendarFeed(e.getUsuarioId(), e.getTokenHash(), e.getCreadoEn());
    }
}
