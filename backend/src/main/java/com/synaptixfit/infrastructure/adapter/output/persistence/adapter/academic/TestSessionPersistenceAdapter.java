package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.TestSession;
import com.synaptixfit.domain.model.academic.TestSessionStatus;
import com.synaptixfit.domain.port.output.academic.TestSessionRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.TestSessionEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicDbCodes;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.TestSessionJpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Repository;

/** Implementa {@link TestSessionRepositoryPort} con JPA. */
@Repository
public class TestSessionPersistenceAdapter implements TestSessionRepositoryPort {

    private final TestSessionJpaRepository repository;

    public TestSessionPersistenceAdapter(TestSessionJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<TestSession> findByIdAndUser(UUID id, UUID userId) {
        return repository.findByIdAndUserId(id, userId).map(AcademicPersistenceMapper::toDomain);
    }

    @Override
    public Optional<TestSession> findActive(UUID userId, UUID materialId) {
        return repository.findFirstByUserIdAndMaterialIdAndStatusOrderByStartedAtDesc(userId, materialId,
                AcademicDbCodes.sessionStatus(TestSessionStatus.IN_PROGRESS)).map(AcademicPersistenceMapper::toDomain);
    }

    @Override
    public List<TestSession> findByUser(UUID userId, UUID materialId, TestSessionStatus status) {
        Specification<TestSessionEntity> spec = (root, query, cb) -> cb.equal(root.get("userId"), userId);
        if (materialId != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("materialId"), materialId));
        }
        if (status != null) {
            String dbStatus = AcademicDbCodes.sessionStatus(status);
            spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), dbStatus));
        }
        return repository.findAll(spec, Sort.by(Sort.Direction.DESC, "startedAt")).stream()
                .map(AcademicPersistenceMapper::toDomain).toList();
    }

    @Override
    public TestSession save(TestSession session) {
        TestSessionEntity entity = repository.findById(session.id()).orElseGet(TestSessionEntity::new);
        AcademicPersistenceMapper.copy(session, entity);
        // Se vuelca al momento: indicadores leen test_sessions con JDBC en la misma transacción.
        return AcademicPersistenceMapper.toDomain(repository.saveAndFlush(entity));
    }
}
