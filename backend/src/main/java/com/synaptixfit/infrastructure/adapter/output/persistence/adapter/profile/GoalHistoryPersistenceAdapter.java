package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.profile;

import com.synaptixfit.domain.model.profile.GoalHistoryEntry;
import com.synaptixfit.domain.port.output.profile.GoalHistoryRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile.GoalHistoryEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.profile.ProfilePersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.profile.GoalHistoryJpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link GoalHistoryRepositoryPort} con JPA. */
@Repository
public class GoalHistoryPersistenceAdapter implements GoalHistoryRepositoryPort {

    private final GoalHistoryJpaRepository repository;

    public GoalHistoryPersistenceAdapter(GoalHistoryJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<GoalHistoryEntry> findOpen(UUID userId) {
        return repository.findFirstByUsuarioIdAndFechaFinIsNullOrderByFechaInicioDescCreadoEnDesc(userId)
                .map(ProfilePersistenceMapper::toDomain);
    }

    @Override
    public GoalHistoryEntry save(GoalHistoryEntry entry) {
        GoalHistoryEntity entity = repository.findById(entry.id()).orElseGet(GoalHistoryEntity::new);
        ProfilePersistenceMapper.copyToEntity(entry, entity);
        // Se fuerza el volcado para que el índice único de "un periodo abierto" vea el cierre antes de la inserción.
        return ProfilePersistenceMapper.toDomain(repository.saveAndFlush(entity));
    }

    @Override
    public List<GoalHistoryEntry> findByUser(UUID userId) {
        return repository.findByUsuarioIdOrderByFechaInicioDescCreadoEnDesc(userId).stream()
                .map(ProfilePersistenceMapper::toDomain).toList();
    }
}
