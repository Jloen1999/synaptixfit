package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.planner;

import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.CalendarBlockEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.planner.PlannerPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.planner.CalendarBlockJpaRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link CalendarBlockRepositoryPort} con JPA. Guardar y borrar un bloque se vuelcan al
 * momento porque retos, indicadores e insignias leen {@code horarios_academicos} con JDBC dentro de la
 * misma transacción (oyentes de {@code StudyBlockCompletionChanged}).
 */
@Repository
public class CalendarBlockPersistenceAdapter implements CalendarBlockRepositoryPort {

    private final CalendarBlockJpaRepository repository;
    private final Clock clock;

    public CalendarBlockPersistenceAdapter(CalendarBlockJpaRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public CalendarBlock save(CalendarBlock block) {
        CalendarBlockEntity entity = repository.findById(block.id()).orElseGet(CalendarBlockEntity::new);
        copy(block, entity);
        return PlannerPersistenceMapper.toDomain(repository.saveAndFlush(entity));
    }

    @Override
    public List<CalendarBlock> saveAll(List<CalendarBlock> blocks) {
        if (blocks.isEmpty()) {
            return List.of();
        }
        Map<UUID, CalendarBlockEntity> existing = repository.findAllById(blocks.stream().map(CalendarBlock::id).toList())
                .stream().collect(Collectors.toMap(CalendarBlockEntity::getId, Function.identity()));
        List<CalendarBlockEntity> entities = blocks.stream().map(b -> {
            CalendarBlockEntity e = existing.getOrDefault(b.id(), new CalendarBlockEntity());
            copy(b, e);
            return e;
        }).toList();
        return repository.saveAll(entities).stream().map(PlannerPersistenceMapper::toDomain).toList();
    }

    private void copy(CalendarBlock block, CalendarBlockEntity entity) {
        PlannerPersistenceMapper.copyToEntity(block, entity);
        if (entity.getCreadoEn() == null) {
            Instant created = block.createdAt();
            entity.setCreadoEn(created == null ? clock.instant() : created);
        }
    }

    @Override
    public Optional<CalendarBlock> findById(UUID id) {
        return repository.findById(id).map(PlannerPersistenceMapper::toDomain);
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
        repository.flush();
    }

    @Override
    public List<CalendarBlock> findOverlapping(UUID userId, Instant from, Instant to, UUID subjectId) {
        List<CalendarBlockEntity> rows = subjectId == null
                ? repository.findByUsuarioIdAndHoraInicioLessThanAndHoraFinGreaterThanOrderByHoraInicioAsc(userId, to, from)
                : repository.findByUsuarioIdAndAsignaturaIdAndHoraInicioLessThanAndHoraFinGreaterThanOrderByHoraInicioAsc(
                        userId, subjectId, to, from);
        return rows.stream().map(PlannerPersistenceMapper::toDomain).toList();
    }

    @Override
    public Map<String, CalendarBlock> findByIcsUids(UUID userId, Collection<String> icsUids) {
        if (icsUids.isEmpty()) {
            return Map.of();
        }
        return repository.findByUsuarioIdAndIcsUidIn(userId, icsUids).stream()
                .map(PlannerPersistenceMapper::toDomain)
                .collect(Collectors.toMap(CalendarBlock::icsUid, Function.identity(), (a, b) -> a));
    }

    @Override
    public List<CalendarBlock> findPendingReviews(UUID userId, UUID studyMaterialId) {
        return repository.findByUsuarioIdAndMaterialEstudioIdAndCompletadoFalseOrderByHoraInicioAsc(userId,
                studyMaterialId).stream().map(PlannerPersistenceMapper::toDomain).toList();
    }

    @Override
    public List<CalendarBlock> findBySubject(UUID userId, UUID subjectId) {
        return repository.findByUsuarioIdAndAsignaturaId(userId, subjectId).stream()
                .map(PlannerPersistenceMapper::toDomain).toList();
    }
}
