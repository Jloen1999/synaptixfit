package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.training.SessionLabel;
import com.synaptixfit.domain.port.output.training.SessionLabelQueryPort;
import java.util.Collection;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/** Implementa {@link SessionLabelQueryPort}: rutina, semana y día de cada sesión con un JOIN. */
@Repository
public class SessionLabelJdbcAdapter implements SessionLabelQueryPort {

    private final JdbcClient jdbc;

    public SessionLabelJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Map<UUID, SessionLabel> labels(Collection<UUID> sessionIds) {
        if (sessionIds.isEmpty()) {
            return Map.of();
        }
        return jdbc.sql("""
                        SELECT s.id, r.nombre AS rutina, d.nombre AS dia, d.numero_dia, sr.numero_semana
                        FROM sesiones_registradas s
                        LEFT JOIN rutinas r ON r.id = s.rutina_id
                        LEFT JOIN dias_rutina d ON d.id = s.dia_id
                        LEFT JOIN semanas_rutina sr ON sr.id = d.semana_id
                        WHERE s.id IN (:ids)
                        """)
                .param("ids", sessionIds)
                .query((rs, n) -> {
                    String day = rs.getString("dia");
                    // getInt + wasNull: no depende del tipo numérico que devuelva cada driver (ADR 0012).
                    int dayNumber = rs.getInt("numero_dia");
                    Integer dayNo = rs.wasNull() ? null : dayNumber;
                    int weekNumber = rs.getInt("numero_semana");
                    Integer weekNo = rs.wasNull() ? null : weekNumber;
                    return new SessionLabel(rs.getObject("id", UUID.class), rs.getString("rutina"),
                            day == null || day.isBlank() ? null : day, dayNo, weekNo);
                })
                .list().stream()
                .collect(Collectors.toMap(SessionLabel::sessionId, l -> l));
    }
}
