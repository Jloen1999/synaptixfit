package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.planner;

import com.synaptixfit.domain.model.planner.ActivityKind;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.LoggedSportActivity;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.planner.LoggedActivityRepositoryPort;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link LoggedActivityRepositoryPort} sobre {@code actividades_apuntadas} (V1041) y los bloques de deporte
 * completados de {@code horarios_academicos}; el esfuerzo sale de su registro de carga física
 * ({@code registros_carga_fisica.bloque_id}). Los minutos del bloque se calculan en Java (SQL estándar).
 */
@Component
public class LoggedActivityJdbcAdapter implements LoggedActivityRepositoryPort {

    private final JdbcClient jdbc;

    public LoggedActivityJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void save(UUID blockId, UUID userId, ActivityKind kind, int minutes, Integer distanceMeters, Instant now) {
        jdbc.sql("INSERT INTO actividades_apuntadas (bloque_id, usuario_id, clase, minutos_reales, distancia_metros,"
                        + " creado_en) VALUES (:block, :user, :kind, :minutes, :distance, :now)")
                .param("block", blockId)
                .param("user", userId)
                .param("kind", kind.name())
                .param("minutes", minutes)
                .param("distance", distanceMeters)
                .param("now", Timestamp.from(now))
                .update();
    }

    @Override
    public PageResult<LoggedSportActivity> findSportActivities(UUID userId, PageRequest page) {
        String sport = ActivityType.SPORT.code();
        long total = jdbc.sql("SELECT COUNT(*) FROM horarios_academicos b WHERE b.usuario_id = :user"
                        + " AND b.tipo_actividad = :sport AND b.completado = true")
                .param("user", userId)
                .param("sport", sport)
                .query(Long.class)
                .single();
        var items = jdbc.sql("SELECT b.id, b.hora_inicio, b.hora_fin, b.temas, a.clase, a.minutos_reales,"
                        + " a.distancia_metros, r.rpe_sesion FROM horarios_academicos b"
                        + " LEFT JOIN actividades_apuntadas a ON a.bloque_id = b.id"
                        + " LEFT JOIN registros_carga_fisica r ON r.bloque_id = b.id"
                        + " WHERE b.usuario_id = :user AND b.tipo_actividad = :sport AND b.completado = true"
                        + " ORDER BY b.hora_inicio DESC LIMIT :size OFFSET :offset")
                .param("user", userId)
                .param("sport", sport)
                .param("size", page.size())
                .param("offset", page.offset())
                .query((rs, n) -> {
                    Instant blockStart = rs.getTimestamp("hora_inicio").toInstant();
                    Instant blockEnd = rs.getTimestamp("hora_fin").toInstant();
                    Integer real = (Integer) rs.getObject("minutos_reales");
                    int minutes = real != null ? real : (int) Duration.between(blockStart, blockEnd).toMinutes();
                    // Una actividad corta ocupa el bloque mínimo terminando cuando terminó: su inicio real es antes.
                    Instant start = real != null ? blockEnd.minus(Duration.ofMinutes(real)) : blockStart;
                    String kind = rs.getString("clase");
                    Number effort = (Number) rs.getObject("rpe_sesion");
                    return new LoggedSportActivity(rs.getObject("id", UUID.class), start, minutes,
                            rs.getString("temas"), kind == null ? null : ActivityKind.valueOf(kind),
                            (Integer) rs.getObject("distancia_metros"),
                            effort == null ? null : (int) Math.round(effort.doubleValue()));
                })
                .list();
        return new PageResult<>(items, page.page(), page.size(), total);
    }
}
