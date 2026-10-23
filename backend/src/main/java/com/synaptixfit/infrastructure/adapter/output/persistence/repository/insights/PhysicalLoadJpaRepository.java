package com.synaptixfit.infrastructure.adapter.output.persistence.repository.insights;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.insights.PhysicalLoadEntity;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data para {@code registros_carga_fisica}: solo lecturas de filas; los agregados se calculan en el dominio. */
public interface PhysicalLoadJpaRepository extends JpaRepository<PhysicalLoadEntity, UUID> {

    Optional<PhysicalLoadEntity> findByUsuarioIdAndSesionId(UUID usuarioId, UUID sesionId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from PhysicalLoadEntity r where r.usuarioId = :userId and r.sesionId = :sessionId")
    int deleteBySession(@Param("userId") UUID userId, @Param("sessionId") UUID sessionId);

    List<PhysicalLoadEntity> findByUsuarioIdAndFechaRegistroBetween(UUID usuarioId, LocalDate from, LocalDate to);

    List<PhysicalLoadEntity> findByUsuarioId(UUID usuarioId);
}
