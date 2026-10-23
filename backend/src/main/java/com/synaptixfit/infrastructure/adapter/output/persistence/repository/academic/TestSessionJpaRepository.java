package com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.TestSessionEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

/** Spring Data para {@code test_sessions}. */
public interface TestSessionJpaRepository extends JpaRepository<TestSessionEntity, UUID>,
        JpaSpecificationExecutor<TestSessionEntity> {

    Optional<TestSessionEntity> findByIdAndUserId(UUID id, UUID userId);

    Optional<TestSessionEntity> findFirstByUserIdAndMaterialIdAndStatusOrderByStartedAtDesc(UUID userId,
                                                                                         UUID materialId,
                                                                                         String status);
}
