package com.synaptixfit.infrastructure.adapter.output.persistence.repository.training;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.ExerciseSelectionEntity;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code seleccion_de_ejercicios}. */
public interface ExerciseSelectionJpaRepository extends JpaRepository<ExerciseSelectionEntity, UUID> {

    List<ExerciseSelectionEntity> findByRutinaIdInAndDiaIdIsNotNull(Collection<UUID> rutinaIds);

    boolean existsByEjercicioId(UUID ejercicioId);
}
