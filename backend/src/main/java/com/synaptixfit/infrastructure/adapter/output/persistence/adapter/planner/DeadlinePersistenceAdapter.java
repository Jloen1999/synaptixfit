package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.planner;

import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.DeadlineEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.planner.PlannerPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.planner.DeadlineJpaRepository;
import jakarta.persistence.criteria.Predicate;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Repository;

/** Implementa {@link DeadlineRepositoryPort} con JPA. */
@Repository
public class DeadlinePersistenceAdapter implements DeadlineRepositoryPort {

    private static final Sort BY_DUE = Sort.by(Sort.Order.asc("fechaLimite"), Sort.Order.asc("id"));

    private final DeadlineJpaRepository repository;
    private final Clock clock;

    public DeadlinePersistenceAdapter(DeadlineJpaRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public Deadline save(Deadline deadline) {
        DeadlineEntity entity = repository.findById(deadline.id()).orElseGet(DeadlineEntity::new);
        PlannerPersistenceMapper.copyToEntity(deadline, entity);
        if (entity.getCreadoEn() == null) {
            entity.setCreadoEn(deadline.createdAt() == null ? clock.instant() : deadline.createdAt());
        }
        entity.setActualizadoEn(clock.instant());
        return PlannerPersistenceMapper.toDomain(repository.save(entity));
    }

    @Override
    public Optional<Deadline> findById(UUID id) {
        return repository.findById(id).map(PlannerPersistenceMapper::toDomain);
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
    }

    @Override
    public PageResult<Deadline> find(UUID userId, Query query, PageRequest page) {
        Page<DeadlineEntity> result = repository.findAll(spec(userId, query),
                org.springframework.data.domain.PageRequest.of(page.page(), page.size(), BY_DUE));
        return new PageResult<>(result.getContent().stream().map(PlannerPersistenceMapper::toDomain).toList(),
                page.page(), page.size(), result.getTotalElements());
    }

    @Override
    public List<Deadline> findAll(UUID userId, Query query) {
        return repository.findAll(spec(userId, query), BY_DUE).stream().map(PlannerPersistenceMapper::toDomain).toList();
    }

    @Override
    public Map<String, Deadline> findByIcsUids(UUID userId, Collection<String> icsUids) {
        if (icsUids.isEmpty()) {
            return Map.of();
        }
        return repository.findByUsuarioIdAndIcsUidIn(userId, icsUids).stream()
                .map(PlannerPersistenceMapper::toDomain)
                .collect(Collectors.toMap(Deadline::icsUid, Function.identity(), (a, b) -> a));
    }

    private static Specification<DeadlineEntity> spec(UUID userId, Query q) {
        return (root, cq, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("usuarioId"), userId));
            if (q.from() != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.<Instant>get("fechaLimite"), q.from()));
            }
            if (q.to() != null) {
                predicates.add(cb.lessThan(root.<Instant>get("fechaLimite"), q.to()));
            }
            if (q.subjectId() != null) {
                predicates.add(cb.equal(root.get("asignaturaId"), q.subjectId()));
            }
            if (q.pendingOnly()) {
                predicates.add(cb.isFalse(root.get("estaCompletado")));
            }
            return cb.and(predicates.toArray(Predicate[]::new));
        };
    }
}
