package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.port.output.training.RoutineCalendarPort;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link RoutineCalendarPort} leyendo con SQL los bloques del calendario
 * ({@code horarios_academicos}, tabla del Planificador) enlazados a los días de una rutina. Solo trae
 * datos: qué fecha se propone lo decide {@code RoutineSchedule}.
 */
@Repository
public class RoutineCalendarJdbcAdapter implements RoutineCalendarPort {

    private final JdbcClient jdbc;

    public RoutineCalendarJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Map<UUID, List<Instant>> pendingBlockStarts(UUID userId, UUID routineId) {
        Map<UUID, List<Instant>> starts = new HashMap<>();
        jdbc.sql("""
                        SELECT h.dia_rutina_id, h.hora_inicio
                        FROM horarios_academicos h
                        JOIN dias_rutina d ON d.id = h.dia_rutina_id
                        JOIN semanas_rutina s ON s.id = d.semana_id
                        WHERE h.usuario_id = :u AND s.rutina_id = :r AND h.completado = false
                        ORDER BY h.hora_inicio
                        """)
                .param("u", userId).param("r", routineId)
                .query((ResultSet rs) -> {
                    Timestamp start = rs.getTimestamp("hora_inicio");
                    if (start != null) {
                        starts.computeIfAbsent(rs.getObject("dia_rutina_id", UUID.class), k -> new ArrayList<>())
                                .add(start.toInstant());
                    }
                });
        return starts;
    }
}
