package com.synaptixfit.infrastructure.adapter.output.persistence.repository;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.PasswordResetTokenEntity;
import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data para {@code restablecimientos_contrasena}. */
public interface PasswordResetTokenJpaRepository extends JpaRepository<PasswordResetTokenEntity, UUID> {

    /**
     * Con bloqueo de fila (SELECT … FOR UPDATE, SQL estándar): dos confirmaciones a la vez del mismo enlace se
     * hacen una detrás de otra y la segunda ya lo ve usado, así que el enlace sirve una sola vez.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<PasswordResetTokenEntity> findByTokenHash(String tokenHash);

    int countByUsuarioIdAndCreadoEnAfter(UUID usuarioId, Instant since);

    @Modifying
    @Query("update PasswordResetTokenEntity t set t.usadoEn = :when where t.usuarioId = :userId and t.usadoEn is null")
    int invalidateAllForUser(@Param("userId") UUID userId, @Param("when") Instant when);
}
