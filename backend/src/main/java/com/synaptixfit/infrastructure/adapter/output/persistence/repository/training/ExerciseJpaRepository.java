package com.synaptixfit.infrastructure.adapter.output.persistence.repository.training;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.ExerciseEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code ejercicios}. */
public interface ExerciseJpaRepository extends JpaRepository<ExerciseEntity, UUID> {
}
