package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.together;

import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.TogetherMember;
import com.synaptixfit.domain.model.together.TogetherMembers;
import com.synaptixfit.domain.model.together.WorkoutTogether;
import com.synaptixfit.domain.port.output.together.WorkoutTogetherRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.admin.JdbcValues;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link WorkoutTogetherRepositoryPort} sobre {@code entrenos_juntos} y {@code entrenos_juntos_miembros}
 * (V1064, ADR 0044). La sesión de cada persona va en su fila de miembro; la hora de inicio común y la pausa del grupo,
 * en la del entreno (V1068, ADR 0047).
 */
@Component
public class WorkoutTogetherJdbcAdapter implements WorkoutTogetherRepositoryPort {

    private final JdbcClient jdbc;

    public WorkoutTogetherJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    private record Head(UUID id, UUID hostId, UUID routineId, UUID dayId, LocalDate date, Instant createdAt,
                        Instant startedAt, UUID startedBy, Instant pausedAt, UUID pausedBy) {
    }

    @Override
    public Optional<WorkoutTogether> findById(UUID id) {
        return jdbc.sql("SELECT id, anfitrion_id, rutina_id, dia_rutina_id, fecha, creado_en, empezado_en,"
                        + " empezado_por, pausado_en, pausado_por FROM entrenos_juntos WHERE id = :id")
                .param("id", id)
                .query((rs, n) -> new Head(rs.getObject("id", UUID.class), rs.getObject("anfitrion_id", UUID.class),
                        rs.getObject("rutina_id", UUID.class), rs.getObject("dia_rutina_id", UUID.class),
                        JdbcValues.date(rs, "fecha"), JdbcValues.instant(rs, "creado_en"),
                        JdbcValues.instant(rs, "empezado_en"), rs.getObject("empezado_por", UUID.class),
                        JdbcValues.instant(rs, "pausado_en"),
                        rs.getObject("pausado_por", UUID.class)))
                .optional()
                .map(this::toDomain);
    }

    @Override
    public Optional<WorkoutTogether> findByIdForUpdate(UUID id) {
        // Bloquea la fila del entreno y después lo lee entero (SELECT … FOR UPDATE, en database_portability.md).
        return jdbc.sql("SELECT id FROM entrenos_juntos WHERE id = :id FOR UPDATE")
                .param("id", id)
                .query(UUID.class)
                .optional()
                .flatMap(this::findById);
    }

    @Override
    public List<WorkoutTogether> findVisibleTo(UUID userId, LocalDate from) {
        return jdbc.sql("SELECT w.id FROM entrenos_juntos w JOIN entrenos_juntos_miembros m ON m.entreno_id = w.id"
                        + " WHERE m.usuario_id = :user AND m.estado IN (:statuses) AND w.fecha >= :from"
                        + " ORDER BY w.creado_en")
                .param("user", userId)
                .param("statuses", TogetherSql.VISIBLE)
                .param("from", from)
                .query(UUID.class)
                .list().stream().map(this::findById).flatMap(Optional::stream).toList();
    }

    @Override
    public Optional<WorkoutTogether> findBySession(UUID sessionId) {
        return jdbc.sql("SELECT entreno_id FROM entrenos_juntos_miembros WHERE sesion_id = :session")
                .param("session", sessionId)
                .query(UUID.class)
                .list().stream().findFirst().flatMap(this::findById);
    }

    @Override
    public WorkoutTogether save(WorkoutTogether w) {
        boolean exists = jdbc.sql("SELECT count(*) FROM entrenos_juntos WHERE id = :id").param("id", w.id())
                .query(Long.class).single() > 0;
        if (!exists) {
            jdbc.sql("INSERT INTO entrenos_juntos (id, anfitrion_id, rutina_id, dia_rutina_id, fecha, creado_en)"
                            + " VALUES (:id, :host, :routine, :day, :date, :created)")
                    .param("id", w.id())
                    .param("host", w.hostId())
                    .param("routine", w.routineId())
                    .param("day", w.dayId())
                    .param("date", w.date())
                    .param("created", JdbcValues.param(w.createdAt()))
                    .update();
        }
        jdbc.sql("UPDATE entrenos_juntos SET empezado_en = :started, empezado_por = :startedBy,"
                        + " pausado_en = :paused, pausado_por = :pausedBy WHERE id = :id")
                .param("started", JdbcValues.param(w.startedAt()))
                .param("startedBy", w.startedBy())
                .param("paused", JdbcValues.param(w.pausedAt()))
                .param("pausedBy", w.pausedBy())
                .param("id", w.id())
                .update();
        for (TogetherMember m : w.members().all()) {
            UUID session = w.sessionOf(m.userId()).orElse(null);
            int updated = jdbc.sql("UPDATE entrenos_juntos_miembros SET estado = :status, sesion_id = :session,"
                            + " actualizado_en = :at WHERE entreno_id = :id AND usuario_id = :user")
                    .param("status", m.status().name())
                    .param("session", session)
                    .param("at", JdbcValues.param(m.updatedAt()))
                    .param("id", w.id())
                    .param("user", m.userId())
                    .update();
            if (updated == 0) {
                jdbc.sql("INSERT INTO entrenos_juntos_miembros (entreno_id, usuario_id, estado, sesion_id,"
                                + " actualizado_en) VALUES (:id, :user, :status, :session, :at)")
                        .param("id", w.id())
                        .param("user", m.userId())
                        .param("status", m.status().name())
                        .param("session", session)
                        .param("at", JdbcValues.param(m.updatedAt()))
                        .update();
            }
        }
        return w;
    }

    private WorkoutTogether toDomain(Head h) {
        List<TogetherMember> members = new ArrayList<>();
        Map<UUID, UUID> sessions = new HashMap<>();
        jdbc.sql("SELECT usuario_id, estado, sesion_id, actualizado_en FROM entrenos_juntos_miembros"
                        + " WHERE entreno_id = :id ORDER BY actualizado_en, usuario_id")
                .param("id", h.id())
                .query((rs, n) -> {
                    UUID user = rs.getObject("usuario_id", UUID.class);
                    UUID session = rs.getObject("sesion_id", UUID.class);
                    if (session != null) {
                        sessions.put(user, session);
                    }
                    return new TogetherMember(user, MemberStatus.valueOf(rs.getString("estado")),
                            JdbcValues.instant(rs, "actualizado_en"));
                })
                .list()
                .forEach(members::add);
        return new WorkoutTogether(h.id(), h.hostId(), h.routineId(), h.dayId(), h.date(), h.createdAt(),
                new TogetherMembers(members), sessions, h.startedAt(), h.startedBy(), h.pausedAt(), h.pausedBy());
    }
}
