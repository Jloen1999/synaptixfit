package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.badge;

import com.synaptixfit.domain.model.badge.StreakPause;
import com.synaptixfit.domain.port.output.badge.StreakPauseRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.badge.StreakPauseEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.badge.StreakPauseJpaRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link StreakPauseRepositoryPort} con JPA. */
@Repository
public class StreakPausePersistenceAdapter implements StreakPauseRepositoryPort {

    private final StreakPauseJpaRepository repository;

    public StreakPausePersistenceAdapter(StreakPauseJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<StreakPause> findByUser(UUID userId) {
        return repository.findByUsuarioIdOrderByDesdeAsc(userId).stream().map(StreakPausePersistenceAdapter::toDomain)
                .toList();
    }

    @Override
    public StreakPause save(StreakPause pause) {
        StreakPauseEntity e = repository.findById(pause.id()).orElseGet(StreakPauseEntity::new);
        e.setId(pause.id());
        e.setUsuarioId(pause.userId());
        e.setDesde(pause.from());
        e.setHasta(pause.to());
        if (e.getCreadoEn() == null) {
            e.setCreadoEn(pause.createdAt());
        }
        return toDomain(repository.save(e));
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
    }

    private static StreakPause toDomain(StreakPauseEntity e) {
        return new StreakPause(e.getId(), e.getUsuarioId(), e.getDesde(), e.getHasta(), e.getCreadoEn());
    }
}
