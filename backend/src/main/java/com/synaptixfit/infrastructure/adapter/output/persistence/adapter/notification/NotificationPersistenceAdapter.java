package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.notification;

import com.synaptixfit.domain.model.notification.Notification;
import com.synaptixfit.domain.model.notification.NotificationPriority;
import com.synaptixfit.domain.model.notification.UnreadCounts;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.notification.NotificationRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.notification.NotificationEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.notification.NotificationPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.notification.NotificationJpaRepository;
import java.time.Instant;
import java.util.EnumMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Repository;

/** Implementa {@link NotificationRepositoryPort} con JPA. */
@Repository
public class NotificationPersistenceAdapter implements NotificationRepositoryPort {

    private static final Sort NEWEST_FIRST = Sort.by(Sort.Order.desc("creadoEn"), Sort.Order.desc("id"));

    private final NotificationJpaRepository repository;

    public NotificationPersistenceAdapter(NotificationJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Notification save(Notification notification) {
        NotificationEntity entity = repository.findById(notification.id()).orElseGet(NotificationEntity::new);
        NotificationPersistenceMapper.copyToEntity(notification, entity);
        return NotificationPersistenceMapper.toDomain(repository.saveAndFlush(entity));
    }

    @Override
    public Optional<Notification> findById(UUID id) {
        return repository.findById(id).map(NotificationPersistenceMapper::toDomain);
    }

    @Override
    public PageResult<Notification> findByUser(UUID userId, boolean unreadOnly, NotificationPriority priority,
                                               PageRequest page) {
        Pageable pageable = org.springframework.data.domain.PageRequest.of(page.page(), page.size(), NEWEST_FIRST);
        Page<NotificationEntity> result;
        if (priority == null) {
            result = unreadOnly
                    ? repository.findByUsuarioIdAndEstaLeidaFalse(userId, pageable)
                    : repository.findByUsuarioId(userId, pageable);
        } else {
            String dbPriority = NotificationPersistenceMapper.toDb(priority);
            result = unreadOnly
                    ? repository.findByUsuarioIdAndPrioridadAndEstaLeidaFalse(userId, dbPriority, pageable)
                    : repository.findByUsuarioIdAndPrioridad(userId, dbPriority, pageable);
        }
        return new PageResult<>(result.map(NotificationPersistenceMapper::toDomain).getContent(), page.page(),
                page.size(), result.getTotalElements());
    }

    @Override
    public UnreadCounts countUnread(UUID userId) {
        Map<NotificationPriority, Long> counts = new EnumMap<>(NotificationPriority.class);
        for (Object[] row : repository.countUnreadByPriority(userId)) {
            counts.put(NotificationPersistenceMapper.priorityFromDb((String) row[0]), ((Number) row[1]).longValue());
        }
        return new UnreadCounts(counts.getOrDefault(NotificationPriority.CRITICAL, 0L),
                counts.getOrDefault(NotificationPriority.RECOMMENDED, 0L),
                counts.getOrDefault(NotificationPriority.INFORMATIVE, 0L));
    }

    @Override
    public int markAllRead(UUID userId, Instant at) {
        return repository.markAllRead(userId, at);
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
        repository.flush();
    }

    @Override
    public long countCreatedSince(UUID userId, Instant since) {
        return repository.countByUsuarioIdAndCreadoEnGreaterThanEqual(userId, since);
    }

    @Override
    public boolean existsByReferenceKey(UUID userId, String referenceKey) {
        return repository.existsByUsuarioIdAndClaveReferencia(userId, referenceKey);
    }
}
