package com.synaptixfit.infrastructure.adapter.output.persistence.repository.insights;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.insights.CrossRegulationEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CrossRegulationJpaRepository extends JpaRepository<CrossRegulationEntity, UUID> {
}
