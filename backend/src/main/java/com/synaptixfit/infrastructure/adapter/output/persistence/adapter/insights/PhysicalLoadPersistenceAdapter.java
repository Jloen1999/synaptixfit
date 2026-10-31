package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights;

import com.synaptixfit.domain.model.insights.PhysicalLoadHistory;
import com.synaptixfit.domain.model.insights.PhysicalLoadRecord;
import com.synaptixfit.domain.port.output.insights.PhysicalLoadRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.insights.PhysicalLoadEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.insights.InsightsPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.insights.PhysicalLoadJpaRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link PhysicalLoadRepositoryPort} con JPA. Solo devuelve filas: las sumas las hace
 * {@link PhysicalLoadHistory} en los casos de uso (no usa la columna generada {@code carga_diaria}).
 */
@Repository
public class PhysicalLoadPersistenceAdapter implements PhysicalLoadRepositoryPort {

    private final PhysicalLoadJpaRepository repository;

    public PhysicalLoadPersistenceAdapter(PhysicalLoadJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<PhysicalLoadRecord> findBySession(UUID userId, UUID sessionId) {
        return repository.findByUsuarioIdAndSesionId(userId, sessionId).map(InsightsPersistenceMapper::toDomain);
    }

    @Override
    public PhysicalLoadRecord save(PhysicalLoadRecord record) {
        PhysicalLoadEntity entity = repository.findById(record.id()).orElseGet(PhysicalLoadEntity::new);
        InsightsPersistenceMapper.copyToEntity(record, entity);
        repository.saveAndFlush(entity);
        return record;
    }

    @Override
    public boolean deleteBySession(UUID userId, UUID sessionId) {
        return repository.deleteBySession(userId, sessionId) > 0;
    }

    @Override
    public Optional<PhysicalLoadRecord> findByBlock(UUID userId, UUID blockId) {
        return repository.findByUsuarioIdAndBloqueId(userId, blockId).map(InsightsPersistenceMapper::toDomain);
    }

    @Override
    public boolean deleteByBlock(UUID userId, UUID blockId) {
        return repository.deleteByBlock(userId, blockId) > 0;
    }

    @Override
    public List<PhysicalLoadHistory.Entry> entriesBetween(UUID userId, LocalDate from, LocalDate to) {
        return repository.findByUsuarioIdAndFechaRegistroBetween(userId, from, to).stream()
                .map(InsightsPersistenceMapper::toEntry).toList();
    }

    @Override
    public List<PhysicalLoadHistory.Entry> allEntries(UUID userId) {
        return repository.findByUsuarioId(userId).stream().map(InsightsPersistenceMapper::toEntry).toList();
    }
}
