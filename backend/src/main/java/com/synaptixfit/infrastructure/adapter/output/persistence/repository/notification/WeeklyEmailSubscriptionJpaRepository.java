package com.synaptixfit.infrastructure.adapter.output.persistence.repository.notification;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.notification.WeeklyEmailSubscriptionEntity;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

/** Spring Data para {@code suscripciones_resumen_semanal}. */
public interface WeeklyEmailSubscriptionJpaRepository extends JpaRepository<WeeklyEmailSubscriptionEntity, UUID> {

    Optional<WeeklyEmailSubscriptionEntity> findByTokenConfirmacionHash(String hash);

    Optional<WeeklyEmailSubscriptionEntity> findByTokenBaja(String token);

    List<WeeklyEmailSubscriptionEntity> findByEstado(String estado);

    /**
     * Marca la semana como enviada solo si sigue activa. Lleva su propia transacción: el envío semanal corre sin
     * una que lo envuelva (cada usuario por separado) y una actualización JPA no puede ejecutarse fuera de una.
     */
    @Transactional
    @Modifying
    @Query("update WeeklyEmailSubscriptionEntity s set s.ultimaSemanaEnviada = :week, s.actualizadoEn = :now "
            + "where s.usuarioId = :userId and s.estado = :estado")
    int markSent(@Param("userId") UUID userId, @Param("week") LocalDate week, @Param("now") Instant now,
                 @Param("estado") String estado);
}
