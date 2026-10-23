package com.synaptixfit.infrastructure.adapter.output.persistence.repository;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.GlobalSettingsEntity;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code configuracion_global}. */
public interface GlobalSettingsJpaRepository extends JpaRepository<GlobalSettingsEntity, Boolean> {
}
