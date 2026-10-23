package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.admin;

import com.synaptixfit.domain.model.admin.LockdownState;
import com.synaptixfit.domain.port.output.admin.LockdownSettingsPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.GlobalSettingsEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.GlobalSettingsJpaRepository;
import java.time.Clock;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link LockdownSettingsPort} sobre la fila única de {@code configuracion_global}
 * (reutiliza la entidad del núcleo, que solo la lee).
 */
@Repository
public class LockdownSettingsPersistenceAdapter implements LockdownSettingsPort {

    private final GlobalSettingsJpaRepository repository;
    private final Clock clock;

    public LockdownSettingsPersistenceAdapter(GlobalSettingsJpaRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public LockdownState load() {
        return repository.findById(Boolean.TRUE)
                .map(e -> new LockdownState(e.isLockdownActivo(), e.getLockdownIniciadoEn(),
                        e.getLockdownIniciadoPor(), e.getActualizadoEn()))
                .orElseGet(() -> new LockdownState(false, null, null, null));
    }

    @Override
    public void save(LockdownState state) {
        GlobalSettingsEntity entity = repository.findById(Boolean.TRUE).orElseGet(() -> {
            GlobalSettingsEntity created = new GlobalSettingsEntity();
            created.setId(Boolean.TRUE);
            return created;
        });
        entity.setLockdownActivo(state.active());
        entity.setLockdownIniciadoEn(state.startedAt());
        entity.setLockdownIniciadoPor(state.startedBy());
        entity.setActualizadoEn(state.updatedAt() != null ? state.updatedAt() : clock.instant());
        repository.save(entity);
    }
}
