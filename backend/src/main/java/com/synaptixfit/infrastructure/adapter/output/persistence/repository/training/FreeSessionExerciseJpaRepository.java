package com.synaptixfit.infrastructure.adapter.output.persistence.repository.training;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.FreeSessionExerciseEntity;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code ejercicios_sesion_libre}. */
public interface FreeSessionExerciseJpaRepository extends JpaRepository<FreeSessionExerciseEntity, UUID> {

    List<FreeSessionExerciseEntity> findBySesionIdIn(Collection<UUID> sesionIds);
}
