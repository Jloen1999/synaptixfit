package com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.UniversityEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code universidades}. */
public interface UniversityJpaRepository extends JpaRepository<UniversityEntity, UUID> {

    List<UniversityEntity> findAllByOrderByNombreAsc();
}
