package com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.CatalogSubjectEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

/** Spring Data para {@code asignaturas_catalogo}. */
public interface CatalogSubjectJpaRepository extends JpaRepository<CatalogSubjectEntity, UUID>,
        JpaSpecificationExecutor<CatalogSubjectEntity> {
}
