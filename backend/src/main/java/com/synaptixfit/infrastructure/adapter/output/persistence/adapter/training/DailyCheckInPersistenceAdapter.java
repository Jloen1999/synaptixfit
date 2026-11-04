package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.port.output.training.DailyCheckInRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.DailyCheckInEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training.TrainingPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.training.DailyCheckInJpaRepository;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.stereotype.Repository;

/** Implementa {@link DailyCheckInRepositoryPort} con JPA. */
@Repository
public class DailyCheckInPersistenceAdapter implements DailyCheckInRepositoryPort {

    private final DailyCheckInJpaRepository repository;

    public DailyCheckInPersistenceAdapter(DailyCheckInJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<DailyCheckIn> findByUserAndDate(UUID userId, LocalDate date) {
        return repository.findByUsuarioIdAndFecha(userId, date).map(TrainingPersistenceMapper::toDomain);
    }

    @Override
    public DailyCheckIn save(DailyCheckIn checkIn) {
        DailyCheckInEntity entity = repository.findById(checkIn.id()).orElseGet(DailyCheckInEntity::new);
        TrainingPersistenceMapper.copy(checkIn, entity);
        return TrainingPersistenceMapper.toDomain(repository.saveAndFlush(entity));
    }

    @Override
    public PageResult<DailyCheckIn> findByUser(UUID userId, PageRequest page) {
        Page<DailyCheckInEntity> result = repository.findByUsuarioIdOrderByFechaDesc(userId,
                org.springframework.data.domain.PageRequest.of(page.page(), page.size()));
        return new PageResult<>(result.getContent().stream().map(TrainingPersistenceMapper::toDomain).toList(),
                page.page(), page.size(), result.getTotalElements());
    }

    @Override
    public void deleteByUser(UUID userId) {
        repository.deleteByUsuarioId(userId);
    }

    @Override
    public void deleteByUserAndDate(UUID userId, LocalDate date) {
        repository.deleteByUsuarioIdAndFecha(userId, date);
    }
}
