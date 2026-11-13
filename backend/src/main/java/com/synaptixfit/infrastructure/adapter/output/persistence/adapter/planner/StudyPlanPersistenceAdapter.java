package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.planner;

import com.synaptixfit.domain.model.planner.StudyPlan;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.port.output.planner.StudyPlanRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.StudyPlanEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.VisibilityDbMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.planner.PlannerPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.planner.StudyPlanJpaRepository;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Repository;

/** Implementa {@link StudyPlanRepositoryPort} con JPA. */
@Repository
public class StudyPlanPersistenceAdapter implements StudyPlanRepositoryPort {

    private final StudyPlanJpaRepository repository;
    private final Clock clock;

    public StudyPlanPersistenceAdapter(StudyPlanJpaRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public StudyPlan save(StudyPlan plan) {
        StudyPlanEntity entity = repository.findById(plan.id()).orElseGet(StudyPlanEntity::new);
        PlannerPersistenceMapper.copyToEntity(plan, entity);
        if (entity.getCreadoEn() == null) {
            entity.setCreadoEn(clock.instant());
        }
        entity.setActualizadoEn(clock.instant());
        return PlannerPersistenceMapper.toDomain(repository.save(entity));
    }

    @Override
    public StudyPlan saveIfAbsent(StudyPlan plan) {
        repository.insertIfAbsent(plan.id(), plan.userId(), plan.name(), plan.weekStart(), plan.weekEnd(),
                VisibilityDbMapper.toDb(plan.visibility()), clock.instant());
        return findByUserAndWeek(plan.userId(), plan.weekStart()).orElseThrow();
    }

    @Override
    public boolean markExperienceAwarded(UUID planId, int points) {
        return repository.markExperienceAwarded(planId, Math.max(0, points), clock.instant()) == 1;
    }

    @Override
    public Optional<StudyPlan> findById(UUID id) {
        return repository.findById(id).map(PlannerPersistenceMapper::toDomain);
    }

    @Override
    public Optional<StudyPlan> findByUserAndWeek(UUID userId, LocalDate weekStart) {
        return repository.findFirstByUsuarioIdAndSemanaInicioOrderByCreadoEnAsc(userId, weekStart)
                .map(PlannerPersistenceMapper::toDomain);
    }

    @Override
    public PageResult<StudyPlan> findByUser(UUID userId, PageRequest page) {
        Page<StudyPlanEntity> result = repository.findByUsuarioId(userId, org.springframework.data.domain.PageRequest.of(
                page.page(), page.size(), Sort.by(Sort.Order.desc("semanaInicio"), Sort.Order.desc("creadoEn"))));
        return new PageResult<>(result.getContent().stream().map(PlannerPersistenceMapper::toDomain).toList(),
                page.page(), page.size(), result.getTotalElements());
    }

    @Override
    public List<StudyPlan> findNonPrivateByUser(UUID userId) {
        return repository.findByUsuarioIdAndVisibilidadNot(userId, VisibilityDbMapper.toDb(Visibility.PRIVATE)).stream()
                .map(PlannerPersistenceMapper::toDomain).toList();
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
    }
}
