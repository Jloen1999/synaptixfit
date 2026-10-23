package com.synaptixfit.infrastructure.adapter.output.persistence.repository.notification;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.notification.NotificationEntity;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data para {@code notificaciones}. */
public interface NotificationJpaRepository extends JpaRepository<NotificationEntity, UUID> {

    Page<NotificationEntity> findByUsuarioId(UUID usuarioId, Pageable pageable);

    Page<NotificationEntity> findByUsuarioIdAndEstaLeidaFalse(UUID usuarioId, Pageable pageable);

    Page<NotificationEntity> findByUsuarioIdAndPrioridad(UUID usuarioId, String prioridad, Pageable pageable);

    Page<NotificationEntity> findByUsuarioIdAndPrioridadAndEstaLeidaFalse(UUID usuarioId, String prioridad,
                                                                         Pageable pageable);

    long countByUsuarioIdAndCreadoEnGreaterThanEqual(UUID usuarioId, Instant since);

    boolean existsByUsuarioIdAndClaveReferencia(UUID usuarioId, String claveReferencia);

    @Query("""
            select n.prioridad, count(n) from NotificationEntity n
            where n.usuarioId = :userId and n.estaLeida = false
            group by n.prioridad
            """)
    List<Object[]> countUnreadByPriority(@Param("userId") UUID userId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("""
            update NotificationEntity n set n.estaLeida = true, n.leidaEn = :at
            where n.usuarioId = :userId and n.estaLeida = false
            """)
    int markAllRead(@Param("userId") UUID userId, @Param("at") Instant at);
}
