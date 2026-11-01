package com.synaptixfit.infrastructure.adapter.output.persistence.repository.training;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.RoutineEntity;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code rutinas}. */
public interface RoutineJpaRepository extends JpaRepository<RoutineEntity, UUID> {

    Optional<RoutineEntity> findByIdAndEliminadoEnIsNull(UUID id);

    Page<RoutineEntity> findByUsuarioIdAndEliminadoEnIsNullOrderByCreadoEnDesc(UUID usuarioId, Pageable pageable);

    Page<RoutineEntity> findByUsuarioIdAndEstadoAndEliminadoEnIsNullOrderByCreadoEnDesc(UUID usuarioId, String estado, Pageable pageable);

    List<RoutineEntity> findByUsuarioIdAndEliminadoEnIsNull(UUID usuarioId);

    List<RoutineEntity> findByUsuarioIdAndEstadoAndEliminadoEnIsNull(UUID usuarioId, String estado);

    Optional<RoutineEntity> findFirstByUsuarioIdAndEstadoAndEliminadoEnIsNullOrderByCreadoEnDesc(UUID usuarioId, String estado);

    List<RoutineEntity> findByIdInAndEliminadoEnIsNull(Collection<UUID> ids);
}
