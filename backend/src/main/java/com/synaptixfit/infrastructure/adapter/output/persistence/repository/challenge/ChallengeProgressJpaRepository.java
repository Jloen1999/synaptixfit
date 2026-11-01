package com.synaptixfit.infrastructure.adapter.output.persistence.repository.challenge;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.challenge.ChallengeProgressEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code progreso_de_reto}. */
public interface ChallengeProgressJpaRepository extends JpaRepository<ChallengeProgressEntity, UUID> {

    List<ChallengeProgressEntity> findByRetoIdOrderByRegistradoEnDesc(UUID retoId);
}
