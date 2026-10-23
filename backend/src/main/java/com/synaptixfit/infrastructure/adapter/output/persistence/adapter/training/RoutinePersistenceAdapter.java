package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.VisibleRoutine;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.SqlLike;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.ExerciseSelectionEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.RoutineDayEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.RoutineEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.RoutineWeekEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training.RoutinePersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training.TrainingDbValues;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.training.ExerciseSelectionJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.training.RoutineDayJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.training.RoutineJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.training.RoutineWeekJpaRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.data.domain.Page;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Agregado rutina con JPA. Guardar sincroniza los hijos (borra los que ya no existen y actualiza
 * o inserta el resto) conservando los ids, porque sesiones y series los referencian. Las consultas
 * de comunidad leen {@code usuarios} y {@code amistades} con SQL (tablas de otros módulos).
 */
@Repository
public class RoutinePersistenceAdapter implements RoutineRepositoryPort {

    /** Visibilidad para un lector: pública, o de amigos con amistad aceptada; autor activo y sin shadowban. */
    private static final String VISIBLE_TO_VIEWER = " r.eliminado_en IS NULL AND u.eliminado_en IS NULL"
            + " AND u.is_shadowbanned = false AND (r.visibilidad = 'public' OR (r.visibilidad = 'friends' AND EXISTS ("
            + " SELECT 1 FROM amistades a WHERE a.estado = 'aceptada' AND ((a.solicitante_id = :viewer AND a.receptor_id = r.usuario_id)"
            + " OR (a.receptor_id = :viewer AND a.solicitante_id = r.usuario_id)))))";

    private final RoutineJpaRepository routines;
    private final RoutineWeekJpaRepository weeks;
    private final RoutineDayJpaRepository days;
    private final ExerciseSelectionJpaRepository selections;
    private final ExerciseSqlReader exerciseReader;
    private final JdbcClient jdbc;
    private final Clock clock;

    public RoutinePersistenceAdapter(RoutineJpaRepository routines, RoutineWeekJpaRepository weeks,
                                     RoutineDayJpaRepository days, ExerciseSelectionJpaRepository selections,
                                     ExerciseSqlReader exerciseReader, JdbcClient jdbc, Clock clock) {
        this.routines = routines;
        this.weeks = weeks;
        this.days = days;
        this.selections = selections;
        this.exerciseReader = exerciseReader;
        this.jdbc = jdbc;
        this.clock = clock;
    }

    // ------------------------------------------------------------------ lectura

    @Override
    public Optional<Routine> findById(UUID id) {
        return routines.findByIdAndEliminadoEnIsNull(id).map(e -> assemble(List.of(e)).getFirst());
    }

    @Override
    public PageResult<Routine> findByOwner(UUID ownerId, RoutineStatus status, PageRequest page) {
        org.springframework.data.domain.PageRequest pageable =
                org.springframework.data.domain.PageRequest.of(page.page(), page.size());
        Page<RoutineEntity> result = status == null
                ? routines.findByUsuarioIdAndEliminadoEnIsNullOrderByCreadoEnDesc(ownerId, pageable)
                : routines.findByUsuarioIdAndEstadoAndEliminadoEnIsNullOrderByCreadoEnDesc(ownerId,
                        TrainingDbValues.toDb(status), pageable);
        return new PageResult<>(assemble(result.getContent()), page.page(), page.size(), result.getTotalElements());
    }

    @Override
    public List<Routine> findAllByOwner(UUID ownerId) {
        return assemble(routines.findByUsuarioIdAndEliminadoEnIsNull(ownerId));
    }

    @Override
    public Optional<Routine> findLatestActive(UUID ownerId) {
        return routines.findFirstByUsuarioIdAndEstadoAndEliminadoEnIsNullOrderByCreadoEnDesc(ownerId,
                TrainingDbValues.toDb(RoutineStatus.ACTIVE)).map(e -> assemble(List.of(e)).getFirst());
    }

    @Override
    public PageResult<VisibleRoutine> findCommunity(UUID viewerId, String text, TrainingGoal goal, PageRequest page) {
        StringBuilder where = new StringBuilder(" FROM rutinas r JOIN usuarios u ON u.id = r.usuario_id WHERE r.usuario_id <> :viewer AND")
                .append(VISIBLE_TO_VIEWER);
        Map<String, Object> params = new HashMap<>();
        params.put("viewer", viewerId);
        if (goal != null) {
            where.append(" AND r.objetivo = :goal");
            params.put("goal", goal.label());
        }
        if (text != null) {
            where.append(" AND (").append(SqlLike.containsIgnoreCase("r.nombre", "q")).append(" OR ")
                    .append(SqlLike.containsIgnoreCase("r.descripcion", "q")).append(")");
            params.put("q", SqlLike.contains(text));
        }
        long total = jdbc.sql("SELECT count(*)" + where).params(params).query(Long.class).single();
        Map<UUID, String> authors = new LinkedHashMap<>();
        jdbc.sql("SELECT r.id, u.nombre_completo" + where + " ORDER BY r.creado_en DESC, r.id LIMIT :limit OFFSET :offset")
                .params(params).param("limit", page.size()).param("offset", page.offset())
                .query((java.sql.ResultSet rs) -> {
                    authors.put(rs.getObject("id", UUID.class), rs.getString("nombre_completo"));
                });
        Map<UUID, Routine> loaded = assemble(routines.findByIdInAndEliminadoEnIsNull(authors.keySet())).stream()
                .collect(Collectors.toMap(Routine::id, Function.identity()));
        List<VisibleRoutine> items = authors.entrySet().stream().filter(a -> loaded.containsKey(a.getKey()))
                .map(a -> new VisibleRoutine(loaded.get(a.getKey()), a.getValue())).toList();
        return new PageResult<>(items, page.page(), page.size(), total);
    }

    @Override
    public Optional<VisibleRoutine> findVisible(UUID routineId, UUID viewerId) {
        Optional<String> author = jdbc.sql("SELECT u.nombre_completo FROM rutinas r JOIN usuarios u ON u.id = r.usuario_id"
                        + " WHERE r.id = :id AND r.eliminado_en IS NULL AND (r.usuario_id = :viewer OR (" + VISIBLE_TO_VIEWER + "))")
                .param("id", routineId).param("viewer", viewerId).query(String.class).optional();
        if (author.isEmpty()) {
            return Optional.empty();
        }
        return findById(routineId).map(r -> new VisibleRoutine(r, author.get()));
    }

    /** Carga en bloque semanas, días, ejercicios planificados y sus ejercicios para varias rutinas. */
    private List<Routine> assemble(List<RoutineEntity> entities) {
        if (entities.isEmpty()) {
            return List.of();
        }
        List<UUID> ids = entities.stream().map(RoutineEntity::getId).toList();
        List<RoutineWeekEntity> weekEntities = weeks.findByRutinaIdIn(ids);
        List<RoutineDayEntity> dayEntities = weekEntities.isEmpty() ? List.of()
                : days.findBySemanaIdIn(weekEntities.stream().map(RoutineWeekEntity::getId).toList());
        List<ExerciseSelectionEntity> selectionEntities = selections.findByRutinaIdInAndDiaIdIsNotNull(ids);
        Map<UUID, ExerciseRef> refs = exerciseReader.refs(selectionEntities.stream()
                .map(ExerciseSelectionEntity::getEjercicioId).collect(Collectors.toSet()));

        Map<UUID, List<PlannedExercise>> exercisesByDay = new HashMap<>();
        selectionEntities.stream().sorted(Comparator.comparingInt(ExerciseSelectionEntity::getIndiceOrden))
                .forEach(s -> exercisesByDay.computeIfAbsent(s.getDiaId(), k -> new ArrayList<>())
                        .add(RoutinePersistenceMapper.toDomain(s, refs)));
        Map<UUID, List<RoutineDay>> daysByWeek = new HashMap<>();
        dayEntities.forEach(d -> daysByWeek.computeIfAbsent(d.getSemanaId(), k -> new ArrayList<>())
                .add(RoutinePersistenceMapper.toDomain(d, exercisesByDay.getOrDefault(d.getId(), List.of()))));
        Map<UUID, List<RoutineWeek>> weeksByRoutine = new HashMap<>();
        weekEntities.forEach(w -> weeksByRoutine.computeIfAbsent(w.getRutinaId(), k -> new ArrayList<>())
                .add(RoutinePersistenceMapper.toDomain(w, daysByWeek.getOrDefault(w.getId(), List.of()))));
        return entities.stream()
                .map(e -> RoutinePersistenceMapper.toDomain(e, weeksByRoutine.getOrDefault(e.getId(), List.of())))
                .toList();
    }

    // ------------------------------------------------------------------ escritura

    @Override
    public Routine save(Routine routine) {
        Instant now = clock.instant();
        RoutineEntity entity = routines.findById(routine.id()).orElseGet(RoutineEntity::new);
        RoutinePersistenceMapper.copy(routine, entity);
        entity.setActualizadoEn(now);
        routines.saveAndFlush(entity);

        List<UUID> routineIds = List.of(routine.id());
        Map<UUID, RoutineWeekEntity> existingWeeks = byId(weeks.findByRutinaIdIn(routineIds), RoutineWeekEntity::getId);
        Map<UUID, RoutineDayEntity> existingDays = existingWeeks.isEmpty() ? new HashMap<>()
                : byId(days.findBySemanaIdIn(existingWeeks.keySet()), RoutineDayEntity::getId);
        Map<UUID, ExerciseSelectionEntity> existingSelections =
                byId(selections.findByRutinaIdInAndDiaIdIsNotNull(routineIds), ExerciseSelectionEntity::getId);

        Set<UUID> desiredWeeks = routine.weeks().stream().map(RoutineWeek::id).collect(Collectors.toSet());
        Set<UUID> desiredDays = routine.allDays().stream().map(RoutineDay::id).collect(Collectors.toSet());
        Set<UUID> desiredSelections = routine.allDays().stream().flatMap(d -> d.exercises().stream())
                .map(PlannedExercise::id).collect(Collectors.toSet());

        // Borrados de hijos a nietos-primero para no depender del orden de Hibernate.
        deleteMissing(existingSelections, desiredSelections, selections);
        deleteMissing(existingDays, desiredDays, days);
        deleteMissing(existingWeeks, desiredWeeks, weeks);

        // Números de semana y órdenes únicos: los que cambian pasan antes por un valor temporal negativo.
        boolean renumbered = false;
        for (RoutineWeek w : routine.weeks()) {
            RoutineWeekEntity e = existingWeeks.get(w.id());
            if (e != null && e.getNumeroSemana() != w.number()) {
                e.setNumeroSemana(-w.number());
                renumbered = true;
            }
        }
        for (RoutineDay d : routine.allDays()) {
            for (PlannedExercise p : d.exercises()) {
                ExerciseSelectionEntity e = existingSelections.get(p.id());
                if (e != null && e.getIndiceOrden() != p.order()) {
                    e.setIndiceOrden(-p.order());
                    renumbered = true;
                }
            }
        }
        if (renumbered) {
            weeks.flush();
        }

        List<RoutineWeekEntity> weekRows = new ArrayList<>();
        List<RoutineDayEntity> dayRows = new ArrayList<>();
        List<ExerciseSelectionEntity> selectionRows = new ArrayList<>();
        for (RoutineWeek w : routine.weeks()) {
            RoutineWeekEntity we = existingWeeks.getOrDefault(w.id(), null);
            if (we == null) {
                we = new RoutineWeekEntity();
                we.setCreadoEn(now);
            }
            RoutinePersistenceMapper.copy(w, routine.id(), we);
            weekRows.add(we);
            for (RoutineDay d : w.days()) {
                RoutineDayEntity de = existingDays.get(d.id());
                if (de == null) {
                    de = new RoutineDayEntity();
                    de.setCreadoEn(now);
                }
                RoutinePersistenceMapper.copy(d, w.id(), de);
                dayRows.add(de);
                for (PlannedExercise p : d.exercises()) {
                    ExerciseSelectionEntity se = existingSelections.getOrDefault(p.id(), new ExerciseSelectionEntity());
                    RoutinePersistenceMapper.copy(p, routine.id(), d.id(), se);
                    selectionRows.add(se);
                }
            }
        }
        weeks.saveAll(weekRows);
        weeks.flush();
        days.saveAll(dayRows);
        days.flush();
        selections.saveAll(selectionRows);
        selections.flush();
        return routine;
    }

    private static <E> Map<UUID, E> byId(Collection<E> rows, Function<E, UUID> id) {
        Map<UUID, E> map = new HashMap<>();
        rows.forEach(r -> map.put(id.apply(r), r));
        return map;
    }

    private static <E> void deleteMissing(Map<UUID, E> existing, Set<UUID> desired,
                                          org.springframework.data.jpa.repository.JpaRepository<E, UUID> repo) {
        List<E> toDelete = existing.entrySet().stream().filter(e -> !desired.contains(e.getKey()))
                .map(Map.Entry::getValue).toList();
        if (!toDelete.isEmpty()) {
            repo.deleteAll(toDelete);
            repo.flush();
            existing.keySet().removeIf(k -> !desired.contains(k));
        }
    }
}
