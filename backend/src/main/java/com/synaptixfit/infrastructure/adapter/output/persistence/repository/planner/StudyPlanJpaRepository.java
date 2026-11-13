package com.synaptixfit.infrastructure.adapter.output.persistence.repository.planner;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.StudyPlanEntity;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data para {@code planes_estudio}. */
public interface StudyPlanJpaRepository extends JpaRepository<StudyPlanEntity, UUID> {

    /** El más antiguo si hubiera duplicados heredados de la app antigua. */
    Optional<StudyPlanEntity> findFirstByUsuarioIdAndSemanaInicioOrderByCreadoEnAsc(UUID usuarioId, LocalDate semanaInicio);

    Page<StudyPlanEntity> findByUsuarioId(UUID usuarioId, Pageable pageable);

    List<StudyPlanEntity> findByUsuarioIdAndVisibilidadNot(UUID usuarioId, String visibilidad);

    /**
     * Crea el plan si la semana aún no tiene (índice único {@code ux_planes_estudio_usuario_semana}). Propio de
     * PostgreSQL ({@code ON CONFLICT}): una clave duplicada abortaría la transacción (database_portability.md).
     */
    @Modifying(flushAutomatically = true)
    @Query(value = "INSERT INTO planes_estudio (id, usuario_id, nombre, semana_inicio, semana_fin, visibilidad,"
            + " creado_en, actualizado_en, xp_planificacion_otorgado, xp_planificacion_puntos)"
            + " VALUES (:id, :userId, :name, :weekStart, :weekEnd, :visibility, :now, :now, false, 0)"
            + " ON CONFLICT (usuario_id, semana_inicio) DO NOTHING", nativeQuery = true)
    int insertIfAbsent(@Param("id") UUID id, @Param("userId") UUID userId, @Param("name") String name,
                       @Param("weekStart") LocalDate weekStart, @Param("weekEnd") LocalDate weekEnd,
                       @Param("visibility") String visibility, @Param("now") Instant now);

    /** Anota la experiencia solo si no lo estaba: la fila la actualiza una sola petición (JPQL portable). */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("update StudyPlanEntity p set p.xpPlanificacionOtorgado = true, p.xpPlanificacionPuntos = :points,"
            + " p.actualizadoEn = :now where p.id = :id and p.xpPlanificacionOtorgado = false")
    int markExperienceAwarded(@Param("id") UUID id, @Param("points") int points, @Param("now") Instant now);
}
