package com.synaptixfit.infrastructure.adapter.output.persistence.repository.badge;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.badge.BadgeEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code insignias}. */
public interface BadgeJpaRepository extends JpaRepository<BadgeEntity, UUID> {

    List<BadgeEntity> findAllByOrderByOrdenAsc();
}
