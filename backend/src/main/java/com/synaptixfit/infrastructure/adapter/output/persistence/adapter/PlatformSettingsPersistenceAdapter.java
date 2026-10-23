package com.synaptixfit.infrastructure.adapter.output.persistence.adapter;

import com.synaptixfit.domain.port.output.platform.PlatformSettingsPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.GlobalSettingsEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.GlobalSettingsJpaRepository;
import org.springframework.stereotype.Repository;

/** Implementa {@link PlatformSettingsPort} sobre la fila única de {@code configuracion_global}. */
@Repository
public class PlatformSettingsPersistenceAdapter implements PlatformSettingsPort {

    private final GlobalSettingsJpaRepository repository;

    public PlatformSettingsPersistenceAdapter(GlobalSettingsJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public boolean isLockdownActive() {
        return repository.findById(Boolean.TRUE).map(GlobalSettingsEntity::isLockdownActivo).orElse(false);
    }
}
