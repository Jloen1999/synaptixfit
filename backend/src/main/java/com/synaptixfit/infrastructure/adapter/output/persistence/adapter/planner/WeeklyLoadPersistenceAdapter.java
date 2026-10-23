package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.planner;

import com.synaptixfit.domain.model.planner.WeeklyAcademicLoad;
import com.synaptixfit.domain.port.output.planner.WeeklyLoadRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.WeeklyLoadEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.planner.PlannerPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.planner.WeeklyLoadJpaRepository;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link WeeklyLoadRepositoryPort} con JPA. */
@Repository
public class WeeklyLoadPersistenceAdapter implements WeeklyLoadRepositoryPort {

    private final WeeklyLoadJpaRepository repository;
    private final Clock clock;

    public WeeklyLoadPersistenceAdapter(WeeklyLoadJpaRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public WeeklyAcademicLoad save(WeeklyAcademicLoad load) {
        WeeklyLoadEntity entity = repository.findById(load.id()).orElseGet(WeeklyLoadEntity::new);
        PlannerPersistenceMapper.copyToEntity(load, entity);
        if (entity.getCreadoEn() == null) {
            entity.setCreadoEn(clock.instant());
        }
        entity.setActualizadoEn(clock.instant());
        return PlannerPersistenceMapper.toDomain(repository.save(entity));
    }

    @Override
    public Optional<WeeklyAcademicLoad> findByUserAndWeek(UUID userId, LocalDate weekStart) {
        return repository.findByUsuarioIdAndSemanaInicio(userId, weekStart).map(PlannerPersistenceMapper::toDomain);
    }

    @Override
    public List<WeeklyAcademicLoad> findByUserBetween(UUID userId, LocalDate fromWeek, LocalDate toWeek) {
        return repository.findByUsuarioIdAndSemanaInicioBetweenOrderBySemanaInicioAsc(userId, fromWeek, toWeek)
                .stream().map(PlannerPersistenceMapper::toDomain).toList();
    }
}
