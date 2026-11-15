package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.domain.model.training.SessionLabel;
import com.synaptixfit.domain.port.output.training.SessionLabelQueryPort;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link SessionLabelQueryPort}: rutina, semana y día de cada sesión con un JOIN y la foto de su tarjeta
 * (primer ejercicio del día o, si es libre, el primero apuntado). Las consultas solo traen filas; el «primero» se
 * elige aquí en Java (ADR 0012).
 */
@Repository
public class SessionLabelJdbcAdapter implements SessionLabelQueryPort {

    private final JdbcClient jdbc;

    public SessionLabelJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    private record Row(SessionLabel label, UUID dayId) {
    }

    private record Image(UUID owner, long order, String url) {
    }

    @Override
    public Map<UUID, SessionLabel> labels(Collection<UUID> sessionIds) {
        if (sessionIds.isEmpty()) {
            return Map.of();
        }
        List<Row> rows = jdbc.sql("""
                        SELECT s.id, s.dia_id, r.nombre AS rutina, d.nombre AS dia, d.numero_dia, sr.numero_semana
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
                    return new Row(new SessionLabel(rs.getObject("id", UUID.class), rs.getString("rutina"),
                            day == null || day.isBlank() ? null : day, dayNo, weekNo),
                            dayNo == null ? null : rs.getObject("dia_id", UUID.class));
                })
                .list();
        Map<UUID, String> dayCovers = dayCovers(rows.stream().map(Row::dayId).filter(id -> id != null)
                .collect(Collectors.toSet()));
        Map<UUID, String> setCovers = firstSetCovers(sessionIds);
        Map<UUID, SessionLabel> result = new HashMap<>();
        for (Row row : rows) {
            SessionLabel l = row.label();
            result.put(l.sessionId(), l.withCover(row.dayId() == null ? null : dayCovers.get(row.dayId()),
                    setCovers.get(l.sessionId())));
        }
        return result;
    }

    /** Foto del primer ejercicio de cada día (la regla de {@code RoutineDay.coverExercise}). */
    private Map<UUID, String> dayCovers(Collection<UUID> dayIds) {
        if (dayIds.isEmpty()) {
            return Map.of();
        }
        return firstOf(jdbc.sql("""
                        SELECT sel.dia_id, sel.indice_orden, e.url_preview, e.url_gif
                        FROM seleccion_de_ejercicios sel
                        JOIN ejercicios e ON e.id = sel.ejercicio_id
                        WHERE sel.dia_id IN (:ids)
                        """)
                .param("ids", dayIds)
                .query((rs, n) -> new Image(rs.getObject("dia_id", UUID.class), rs.getInt("indice_orden"),
                        ExerciseRef.stillImage(rs.getString("url_preview"), rs.getString("url_gif"))))
                .list());
    }

    /** Foto del primer ejercicio apuntado en cada sesión (sesiones libres o días que ya no existen). */
    private Map<UUID, String> firstSetCovers(Collection<UUID> sessionIds) {
        return firstOf(jdbc.sql("""
                        SELECT ss.sesion_id, ss.creado_en, e.url_preview, e.url_gif
                        FROM series_sesion ss
                        JOIN ejercicios e ON e.id = ss.ejercicio_id
                        WHERE ss.sesion_id IN (:ids)
                        """)
                .param("ids", sessionIds)
                .query((rs, n) -> new Image(rs.getObject("sesion_id", UUID.class),
                        rs.getTimestamp("creado_en").getTime(),
                        ExerciseRef.stillImage(rs.getString("url_preview"), rs.getString("url_gif"))))
                .list());
    }

    private static Map<UUID, String> firstOf(List<Image> images) {
        Map<UUID, Image> first = new HashMap<>();
        for (Image image : images) {
            if (image.url() == null || image.url().isBlank()) {
                continue;
            }
            first.merge(image.owner(), image, (a, b) -> a.order() <= b.order() ? a : b);
        }
        Map<UUID, String> urls = new HashMap<>();
        first.forEach((owner, image) -> urls.put(owner, image.url()));
        return urls;
    }
}
