package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.notification;

import com.synaptixfit.domain.model.notification.ReminderOptions;
import com.synaptixfit.domain.port.output.notification.ReminderOptionsRepositoryPort;
import java.sql.Time;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link ReminderOptionsRepositoryPort} sobre {@code opciones_avisos} (V1042 y V1046), con actualizar o
 * insertar. Los días antes de una entrega se guardan como tres columnas booleanas (portables, ADR 0012).
 */
@Component
public class ReminderOptionsJdbcAdapter implements ReminderOptionsRepositoryPort {

    private final JdbcClient jdbc;

    public ReminderOptionsJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<ReminderOptions> find(UUID userId) {
        return jdbc.sql("SELECT racha, registro_diario, clases, antelacion_eventos_min, entregas_1_dia,"
                        + " entregas_3_dias, entregas_7_dias, tareas_reto, hora_resumen FROM opciones_avisos"
                        + " WHERE usuario_id = :user")
                .param("user", userId)
                .query((rs, n) -> {
                    Set<Integer> days = new HashSet<>();
                    if (rs.getBoolean("entregas_1_dia")) {
                        days.add(1);
                    }
                    if (rs.getBoolean("entregas_3_dias")) {
                        days.add(3);
                    }
                    if (rs.getBoolean("entregas_7_dias")) {
                        days.add(7);
                    }
                    Time summary = rs.getTime("hora_resumen");
                    return new ReminderOptions(rs.getBoolean("racha"), rs.getBoolean("registro_diario"),
                            rs.getBoolean("clases"), rs.getInt("antelacion_eventos_min"),
                            days.isEmpty() ? ReminderOptions.DEFAULT_DEADLINE_DAYS : days,
                            ReminderOptions.TaskTiming.valueOf(rs.getString("tareas_reto")),
                            summary == null ? null : summary.toLocalTime());
                })
                .optional();
    }

    @Override
    public void save(UUID userId, ReminderOptions options, Instant now) {
        int updated = jdbc.sql("UPDATE opciones_avisos SET racha = :streak, registro_diario = :checkIn,"
                        + " clases = :classes, antelacion_eventos_min = :lead, entregas_1_dia = :d1,"
                        + " entregas_3_dias = :d3, entregas_7_dias = :d7, tareas_reto = :tasks,"
                        + " hora_resumen = :summary, actualizado_en = :now WHERE usuario_id = :user")
                .params(params(userId, options, now))
                .update();
        if (updated == 0) {
            jdbc.sql("INSERT INTO opciones_avisos (usuario_id, racha, registro_diario, clases,"
                            + " antelacion_eventos_min, entregas_1_dia, entregas_3_dias, entregas_7_dias, tareas_reto,"
                            + " hora_resumen, actualizado_en) VALUES (:user, :streak, :checkIn, :classes, :lead, :d1,"
                            + " :d3, :d7, :tasks, :summary, :now)")
                    .params(params(userId, options, now))
                    .update();
        }
    }

    private static Map<String, Object> params(UUID userId, ReminderOptions o, Instant now) {
        Map<String, Object> p = new HashMap<>();
        p.put("user", userId);
        p.put("streak", o.streak());
        p.put("checkIn", o.checkIn());
        p.put("classes", o.classes());
        p.put("lead", o.eventLeadMinutes());
        p.put("d1", o.deadlineDaysBefore().contains(1));
        p.put("d3", o.deadlineDaysBefore().contains(3));
        p.put("d7", o.deadlineDaysBefore().contains(7));
        p.put("tasks", o.taskTiming().name());
        p.put("summary", o.morningSummaryAt() == null ? null : Time.valueOf(o.morningSummaryAt()));
        p.put("now", Timestamp.from(now));
        return p;
    }
}
