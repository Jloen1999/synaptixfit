package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.WeeklyTrainingPlan;
import com.synaptixfit.domain.port.output.training.WeeklyPlanRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.WeeklyPlanEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training.TrainingPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.training.WeeklyPlanJpaRepository;
import java.time.Clock;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.stereotype.Repository;

/** Implementa {@link WeeklyPlanRepositoryPort} con JPA. */
@Repository
public class WeeklyPlanPersistenceAdapter implements WeeklyPlanRepositoryPort {

    private final WeeklyPlanJpaRepository repository;
    private final Clock clock;

    public WeeklyPlanPersistenceAdapter(WeeklyPlanJpaRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public Optional<WeeklyTrainingPlan> findByUserAndWeek(UUID userId, LocalDate weekStart) {
        return repository.findByUsuarioIdAndSemanaInicio(userId, weekStart).map(TrainingPersistenceMapper::toDomain);
    }

    @Override
    public WeeklyTrainingPlan save(WeeklyTrainingPlan plan) {
        WeeklyPlanEntity entity = repository.findById(plan.id()).orElseGet(() -> {
            WeeklyPlanEntity e = new WeeklyPlanEntity();
            e.setCreadoEn(clock.instant());
            return e;
        });
        TrainingPersistenceMapper.copy(plan, entity);
        entity.setActualizadoEn(clock.instant());
        return TrainingPersistenceMapper.toDomain(repository.saveAndFlush(entity));
    }

    @Override
    public void delete(UUID planId) {
        repository.deleteById(planId);
        repository.flush();
    }

    @Override
    public PageResult<WeeklyTrainingPlan> findByUser(UUID userId, PageRequest page) {
        Page<WeeklyPlanEntity> result = repository.findByUsuarioIdOrderBySemanaInicioDesc(userId,
                org.springframework.data.domain.PageRequest.of(page.page(), page.size()));
        return new PageResult<>(result.getContent().stream().map(TrainingPersistenceMapper::toDomain).toList(),
                page.page(), page.size(), result.getTotalElements());
    }
}
