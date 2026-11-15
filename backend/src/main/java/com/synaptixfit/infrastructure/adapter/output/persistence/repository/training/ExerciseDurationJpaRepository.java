package com.synaptixfit.infrastructure.adapter.output.persistence.repository.training;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.ExerciseDurationEntity;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code duraciones_ejercicio_rutina}. */
public interface ExerciseDurationJpaRepository extends JpaRepository<ExerciseDurationEntity, UUID> {

    List<ExerciseDurationEntity> findBySeleccionIdIn(Collection<UUID> seleccionIds);
}
