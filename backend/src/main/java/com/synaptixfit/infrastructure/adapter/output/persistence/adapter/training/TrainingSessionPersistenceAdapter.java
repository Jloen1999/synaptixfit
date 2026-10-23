package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.SessionSetEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.TrainingSessionEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training.TrainingPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.training.SessionSetJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.training.TrainingSessionJpaRepository;
import java.sql.ResultSet;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.data.domain.Page;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/** Sesiones y series con JPA; el historial para el generador se lee con SQL en bloque. */
@Repository
public class TrainingSessionPersistenceAdapter implements TrainingSessionRepositoryPort {

    private final TrainingSessionJpaRepository sessions;
    private final SessionSetJpaRepository sets;
    private final JdbcClient jdbc;
    private final Clock clock;

    public TrainingSessionPersistenceAdapter(TrainingSessionJpaRepository sessions, SessionSetJpaRepository sets,
                                             JdbcClient jdbc, Clock clock) {
        this.sessions = sessions;
        this.sets = sets;
        this.jdbc = jdbc;
        this.clock = clock;
    }

    @Override
    public TrainingSession save(TrainingSession session) {
        TrainingSessionEntity entity = sessions.findById(session.id()).orElseGet(TrainingSessionEntity::new);
        TrainingPersistenceMapper.copy(session, entity);
        sessions.saveAndFlush(entity);

        Map<UUID, SessionSetEntity> existing = new HashMap<>();
        sets.findBySesionIdIn(List.of(session.id())).forEach(s -> existing.put(s.getId(), s));
        Set<UUID> desired = session.sets().stream().map(SessionSet::id).collect(Collectors.toSet());
        List<SessionSetEntity> removed = existing.values().stream().filter(s -> !desired.contains(s.getId())).toList();
        if (!removed.isEmpty()) {
            sets.deleteAll(removed);
            sets.flush();
        }
        List<SessionSetEntity> rows = new ArrayList<>();
        for (SessionSet s : session.sets()) {
            SessionSetEntity e = existing.get(s.id());
            if (e == null) {
                e = new SessionSetEntity();
                e.setCreadoEn(clock.instant());
            }
            TrainingPersistenceMapper.copy(s, session.id(), e);
            rows.add(e);
        }
        sets.saveAll(rows);
        sets.flush();
        return session;
    }

    @Override
    public Optional<TrainingSession> findById(UUID id) {
        return sessions.findById(id).map(e -> withSets(List.of(e)).getFirst());
    }

    @Override
    public Optional<TrainingSession> findInProgressForDay(UUID userId, UUID dayId) {
        return sessions.findFirstByUsuarioIdAndDiaIdAndCompletadaEnIsNullOrderByCreadoEnDesc(userId, dayId)
                .map(e -> withSets(List.of(e)).getFirst());
    }

    @Override
    public boolean existsCompletedForDay(UUID dayId, UUID excludingSessionId) {
        return sessions.existsByDiaIdAndCompletadaEnIsNotNullAndIdNot(dayId, excludingSessionId);
    }

    @Override
    public PageResult<TrainingSession> findByUser(UUID userId, Boolean completed, PageRequest page) {
        org.springframework.data.domain.PageRequest pageable =
                org.springframework.data.domain.PageRequest.of(page.page(), page.size());
        Page<TrainingSessionEntity> result;
        if (completed == null) {
            result = sessions.findByUsuarioIdOrderByCreadoEnDesc(userId, pageable);
        } else if (completed) {
            result = sessions.findByUsuarioIdAndCompletadaEnIsNotNullOrderByCompletadaEnDesc(userId, pageable);
        } else {
            result = sessions.findByUsuarioIdAndCompletadaEnIsNullOrderByCreadoEnDesc(userId, pageable);
        }
        return new PageResult<>(withSets(result.getContent()), page.page(), page.size(), result.getTotalElements());
    }

    @Override
    public Optional<Instant> lastCompletedAt(UUID userId) {
        return sessions.findFirstByUsuarioIdAndCompletadaEnIsNotNullOrderByCompletadaEnDesc(userId)
                .map(TrainingSessionEntity::getCompletadaEn);
    }

    @Override
    public List<CompletedSessionSummary> recentCompleted(UUID userId, int limit) {
        record Head(UUID id, Instant completedAt, Integer rpe, int minutes) {
        }
        List<Head> heads = jdbc.sql("SELECT id, completada_en, rpe, duracion_minutos FROM sesiones_registradas"
                        + " WHERE usuario_id = :u AND completada_en IS NOT NULL ORDER BY completada_en DESC LIMIT :limit")
                .param("u", userId).param("limit", limit)
                .query((rs, n) -> new Head(rs.getObject("id", UUID.class), rs.getTimestamp("completada_en").toInstant(),
                        (Integer) rs.getObject("rpe"), rs.getInt("duracion_minutos")))
                .list();
        if (heads.isEmpty()) {
            return List.of();
        }
        Map<UUID, List<CompletedSessionSummary.PerformedSet>> setsBySession = new HashMap<>();
        jdbc.sql("SELECT ss.id, ss.sesion_id, ss.seleccion_id, ss.numero_serie, ss.repeticiones_realizadas, ss.peso_kg,"
                        + " ss.completada, ss.failed_reps, sel.ejercicio_id, e.nombre FROM series_sesion ss"
                        + " LEFT JOIN seleccion_de_ejercicios sel ON sel.id = ss.seleccion_id"
                        + " LEFT JOIN ejercicios e ON e.id = sel.ejercicio_id WHERE ss.sesion_id IN (:ids)"
                        + " ORDER BY ss.numero_serie")
                .param("ids", heads.stream().map(Head::id).toList())
                .query((ResultSet rs) -> {
                    Object weight = rs.getObject("peso_kg");
                    SessionSet set = new SessionSet(rs.getObject("id", UUID.class), rs.getObject("seleccion_id", UUID.class),
                            Math.max(1, rs.getInt("numero_serie")), (Integer) rs.getObject("repeticiones_realizadas"),
                            weight == null ? null : ((Number) weight).doubleValue(), rs.getBoolean("completada"),
                            Math.max(0, rs.getInt("failed_reps")));
                    setsBySession.computeIfAbsent(rs.getObject("sesion_id", UUID.class), k -> new ArrayList<>())
                            .add(new CompletedSessionSummary.PerformedSet(rs.getObject("ejercicio_id", UUID.class),
                                    rs.getString("nombre"), set));
                });
        return heads.stream().map(h -> new CompletedSessionSummary(h.id(), h.completedAt(), h.rpe(), h.minutes(),
                setsBySession.getOrDefault(h.id(), List.of()))).toList();
    }

    @Override
    public int countCompletedBetween(UUID userId, Instant fromInclusive, Instant toExclusive) {
        return (int) sessions.countByUsuarioIdAndCompletadaEnGreaterThanEqualAndCompletadaEnLessThan(userId,
                fromInclusive, toExclusive);
    }

    @Override
    public void delete(UUID sessionId) {
        sessions.deleteById(sessionId);
        sessions.flush();
    }

    private List<TrainingSession> withSets(List<TrainingSessionEntity> entities) {
        if (entities.isEmpty()) {
            return List.of();
        }
        Map<UUID, List<SessionSetEntity>> bySession = sets.findBySesionIdIn(
                entities.stream().map(TrainingSessionEntity::getId).toList()).stream()
                .collect(Collectors.groupingBy(SessionSetEntity::getSesionId));
        return entities.stream()
                .map(e -> TrainingPersistenceMapper.toDomain(e, bySession.getOrDefault(e.getId(), List.of())))
                .toList();
    }
}
