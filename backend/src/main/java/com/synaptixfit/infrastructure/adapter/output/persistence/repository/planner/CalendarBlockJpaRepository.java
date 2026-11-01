package com.synaptixfit.infrastructure.adapter.output.persistence.repository.planner;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.CalendarBlockEntity;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code horarios_academicos}. */
public interface CalendarBlockJpaRepository extends JpaRepository<CalendarBlockEntity, UUID> {

    /** Bloques que se solapan con [from, to): empiezan antes de {@code to} y terminan después de {@code from}. */
    List<CalendarBlockEntity> findByUsuarioIdAndHoraInicioLessThanAndHoraFinGreaterThanOrderByHoraInicioAsc(
            UUID usuarioId, Instant to, Instant from);

    List<CalendarBlockEntity> findByUsuarioIdAndAsignaturaIdAndHoraInicioLessThanAndHoraFinGreaterThanOrderByHoraInicioAsc(
            UUID usuarioId, UUID asignaturaId, Instant to, Instant from);

    List<CalendarBlockEntity> findByUsuarioIdAndIcsUidIn(UUID usuarioId, Collection<String> icsUids);

    List<CalendarBlockEntity> findByUsuarioIdAndMaterialEstudioIdAndCompletadoFalseOrderByHoraInicioAsc(
            UUID usuarioId, UUID materialEstudioId);

    List<CalendarBlockEntity> findByUsuarioIdAndAsignaturaId(UUID usuarioId, UUID asignaturaId);

    List<CalendarBlockEntity> findByUsuarioIdAndRutinaIdOrderByHoraInicioAsc(UUID usuarioId, UUID rutinaId);

    List<CalendarBlockEntity> findByUsuarioIdAndDiaRutinaIdInOrderByHoraInicioAsc(UUID usuarioId,
                                                                                Collection<UUID> diaRutinaIds);
}
