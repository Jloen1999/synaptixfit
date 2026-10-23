package com.synaptixfit.infrastructure.adapter.output.persistence.repository;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.RefreshTokenEntity;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data para {@code refresh_tokens}. */
public interface RefreshTokenJpaRepository extends JpaRepository<RefreshTokenEntity, UUID> {

    Optional<RefreshTokenEntity> findByTokenHash(String tokenHash);

    @Modifying
    @Query("update RefreshTokenEntity t set t.revocadoEn = :when where t.usuarioId = :userId and t.revocadoEn is null")
    int revokeAllForUser(@Param("userId") UUID userId, @Param("when") Instant when);
}
