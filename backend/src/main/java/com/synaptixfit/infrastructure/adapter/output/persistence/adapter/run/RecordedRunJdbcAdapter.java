package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.run;

import com.synaptixfit.domain.model.planner.ActivityKind;
import com.synaptixfit.domain.model.run.RecordedRun;
import com.synaptixfit.domain.model.run.RunDetail;
import com.synaptixfit.domain.model.run.RunTrack;
import com.synaptixfit.domain.model.run.RunWeek;
import com.synaptixfit.domain.port.output.run.RecordedRunRepositoryPort;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

/**
 * Implementa {@link RecordedRunRepositoryPort} sobre {@code carreras_gps} (V1055). El título y las actividades de la
 * semana se leen de {@code horarios_academicos} y {@code actividades_apuntadas}. La ruta y los tramos van en
 * {@code jsonb} ({@code CAST(... AS jsonb)}, listado en database_portability.md).
 */
@Component
public class RecordedRunJdbcAdapter implements RecordedRunRepositoryPort {

    /** Clases que se miden en distancia y salen en «Esta semana» de Correr. */
    private static final List<String> DISTANCE_KINDS = List.of(ActivityKind.RUN.name(), ActivityKind.WALK.name(),
            ActivityKind.BIKE.name());

    private final JdbcClient jdbc;
    private final RunJsonCodec codec;

    public RecordedRunJdbcAdapter(JdbcClient jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.codec = new RunJsonCodec(json);
    }

    @Override
    public Optional<UUID> findBlockByClientKey(UUID userId, UUID clientKey) {
        return jdbc.sql("SELECT bloque_id FROM carreras_gps WHERE usuario_id = :user AND clave_cliente = :key")
                .param("user", userId)
                .param("key", clientKey)
                .query(UUID.class)
                .optional();
    }

    @Override
    public void save(RecordedRun run) {
        jdbc.sql("""
                        INSERT INTO carreras_gps (bloque_id, usuario_id, clave_cliente, clase, iniciada_en, terminada_en,
                            segundos_movimiento, distancia_metros, desnivel_metros, kcal, esfuerzo, tramos, ruta,
                            entreno_carrera_id, creado_en)
                        VALUES (:block, :user, :key, :kind, :startedAt, :endedAt, :moving, :distance, :elevation,
                            :kcal, :effort, CAST(:splits AS jsonb), CAST(:route AS jsonb), :workout, :createdAt)
                        """)
                .param("block", run.blockId())
                .param("user", run.userId())
                .param("key", run.clientKey())
                .param("kind", run.kind().name())
                .param("startedAt", Timestamp.from(run.startedAt()))
                .param("endedAt", Timestamp.from(run.endedAt()))
                .param("moving", run.metrics().movingSeconds())
                .param("distance", run.metrics().distanceMeters())
                .param("elevation", run.metrics().elevationGainMeters())
                .param("kcal", run.kcal())
                .param("effort", run.effort())
                .param("splits", codec.splits(run.metrics().splits()))
                .param("route", codec.route(run.metrics().points()))
                .param("workout", run.workoutId())
                .param("createdAt", Timestamp.from(run.createdAt()))
                .update();
    }

    @Override
    public Optional<RunDetail> findDetail(UUID userId, UUID blockId, int routePoints) {
        return jdbc.sql("""
                        SELECT c.clase, c.iniciada_en, c.terminada_en, c.segundos_movimiento, c.distancia_metros,
                            c.desnivel_metros, c.kcal, c.esfuerzo, c.tramos, c.ruta, c.entreno_carrera_id, b.temas
                        FROM carreras_gps c JOIN horarios_academicos b ON b.id = c.bloque_id
                        WHERE c.bloque_id = :block AND c.usuario_id = :user
                        """)
                .param("block", blockId)
                .param("user", userId)
                .query((rs, n) -> new RunDetail(blockId, ActivityKind.valueOf(rs.getString("clase")),
                        rs.getString("temas"), rs.getTimestamp("iniciada_en").toInstant(),
                        rs.getTimestamp("terminada_en").toInstant(), rs.getInt("distancia_metros"),
                        rs.getInt("segundos_movimiento"), rs.getInt("desnivel_metros"),
                        (Integer) rs.getObject("kcal"), rs.getInt("esfuerzo"), codec.splits(rs.getString("tramos")),
                        RunTrack.simplify(codec.route(rs.getString("ruta")), routePoints),
                        rs.getObject("entreno_carrera_id", UUID.class)))
                .optional();
    }

    @Override
    public List<RunWeek.Outing> findOutings(UUID userId, Instant from, Instant to) {
        return jdbc.sql("""
                        SELECT b.hora_fin, a.minutos_reales, a.distancia_metros, c.segundos_movimiento,
                            c.distancia_metros AS distancia_gps, c.desnivel_metros
                        FROM actividades_apuntadas a
                        JOIN horarios_academicos b ON b.id = a.bloque_id
                        LEFT JOIN carreras_gps c ON c.bloque_id = a.bloque_id
                        WHERE a.usuario_id = :user AND b.completado = true AND a.clase IN (:kinds)
                            AND b.hora_fin > :from AND b.hora_inicio < :to
                        """)
                .param("user", userId)
                .param("kinds", DISTANCE_KINDS)
                .param("from", Timestamp.from(from))
                .param("to", Timestamp.from(to))
                .query((rs, n) -> {
                    int minutes = rs.getInt("minutos_reales");
                    Instant start = rs.getTimestamp("hora_fin").toInstant().minus(Duration.ofMinutes(minutes));
                    Integer gpsDistance = (Integer) rs.getObject("distancia_gps");
                    Integer manualDistance = (Integer) rs.getObject("distancia_metros");
                    Integer moving = (Integer) rs.getObject("segundos_movimiento");
                    int distance = gpsDistance != null ? gpsDistance : manualDistance == null ? 0 : manualDistance;
                    return new RunWeek.Outing(start, distance, moving != null ? moving : minutes * 60,
                            (Integer) rs.getObject("desnivel_metros"));
                })
                .list();
    }
}
