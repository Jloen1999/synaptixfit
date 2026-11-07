package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.SubjectAgenda;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.port.output.academic.SubjectAgendaPort;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link SubjectAgendaPort} leyendo con {@link JdbcClient} las tablas del planificador
 * ({@code horarios_academicos}, {@code entregas_examenes}); solo trae datos, la elección la hace el dominio.
 */
@Component
public class SubjectAgendaJdbcAdapter implements SubjectAgendaPort {

    private final JdbcClient jdbc;

    public SubjectAgendaJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Map<UUID, List<SubjectAgenda.ClassSlot>> upcomingClasses(UUID userId, List<UUID> subjectIds, Instant from,
                                                                    Instant to) {
        Map<UUID, List<SubjectAgenda.ClassSlot>> out = new HashMap<>();
        if (subjectIds.isEmpty()) {
            return out;
        }
        jdbc.sql("""
                        SELECT asignatura_id, hora_inicio, ubicacion FROM horarios_academicos
                         WHERE usuario_id = :u AND asignatura_id IN (:ids) AND tipo_actividad = :clase
                           AND ausente = FALSE AND hora_inicio >= :from AND hora_inicio < :to
                        """)
                .param("u", userId).param("ids", subjectIds).param("clase", ActivityType.CLASS.code())
                .param("from", Timestamp.from(from)).param("to", Timestamp.from(to))
                .query((rs, n) -> {
                    out.computeIfAbsent(rs.getObject("asignatura_id", UUID.class), k -> new ArrayList<>())
                            .add(new SubjectAgenda.ClassSlot(rs.getTimestamp("hora_inicio").toInstant(),
                                    rs.getString("ubicacion")));
                    return null;
                })
                .list();
        return out;
    }

    @Override
    public Map<UUID, List<SubjectAgenda.Deadline>> pendingDeadlines(UUID userId, List<UUID> subjectIds,
                                                                    Instant from) {
        Map<UUID, List<SubjectAgenda.Deadline>> out = new HashMap<>();
        if (subjectIds.isEmpty()) {
            return out;
        }
        jdbc.sql("""
                        SELECT asignatura_id, titulo, tipo, fecha_limite FROM entregas_examenes
                         WHERE usuario_id = :u AND asignatura_id IN (:ids) AND esta_completado = FALSE
                           AND fecha_limite >= :from
                        """)
                .param("u", userId).param("ids", subjectIds).param("from", Timestamp.from(from))
                .query((rs, n) -> {
                    out.computeIfAbsent(rs.getObject("asignatura_id", UUID.class), k -> new ArrayList<>())
                            .add(new SubjectAgenda.Deadline(rs.getString("titulo"),
                                    rs.getTimestamp("fecha_limite").toInstant(), "examen".equals(rs.getString("tipo"))));
                    return null;
                })
                .list();
        return out;
    }
}
