package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.notification;

import com.synaptixfit.domain.model.notification.NotificationPreferences;
import com.synaptixfit.domain.port.output.notification.NotificationPreferencesRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.notification.NotificationPreferencesEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.notification.NotificationPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.notification.NotificationPreferencesJpaRepository;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link NotificationPreferencesRepositoryPort} con JPA. */
@Repository
public class NotificationPreferencesPersistenceAdapter implements NotificationPreferencesRepositoryPort {

    private final NotificationPreferencesJpaRepository repository;

    public NotificationPreferencesPersistenceAdapter(NotificationPreferencesJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<NotificationPreferences> findByUserId(UUID userId) {
        return repository.findByUsuarioId(userId).map(NotificationPersistenceMapper::toDomain);
    }

    @Override
    public NotificationPreferences save(NotificationPreferences preferences) {
        NotificationPreferencesEntity entity = repository.findById(preferences.id())
                .orElseGet(NotificationPreferencesEntity::new);
        NotificationPersistenceMapper.copyToEntity(preferences, entity);
        return NotificationPersistenceMapper.toDomain(repository.saveAndFlush(entity));
    }
}
