package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.run;

import com.synaptixfit.domain.model.run.PlannedRun;
import com.synaptixfit.domain.model.run.RunWorkout;
import com.synaptixfit.domain.port.output.run.RunWorkoutRepositoryPort;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

/**
 * Implementa {@link RunWorkoutRepositoryPort} sobre {@code entrenos_carrera} y {@code eventos_entreno_carrera}
 * (V1055). Los eventos por hacer se leen de {@code horarios_academicos} (del planificador) con su vínculo.
 */
@Component
public class RunWorkoutJdbcAdapter implements RunWorkoutRepositoryPort {

    private static final String COLUMNS = "id, usuario_id, nombre, plantilla, pasos, creado_en, actualizado_en";

    private final JdbcClient jdbc;
    private final RunJsonCodec codec;

    public RunWorkoutJdbcAdapter(JdbcClient jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.codec = new RunJsonCodec(json);
    }

    @Override
    public RunWorkout save(RunWorkout w) {
        int updated = jdbc.sql("""
                        UPDATE entrenos_carrera SET nombre = :name, pasos = CAST(:steps AS jsonb),
                            actualizado_en = :updatedAt WHERE id = :id
                        """)
                .param("id", w.id())
                .param("name", w.name())
                .param("steps", codec.groups(w.groups()))
                .param("updatedAt", Timestamp.from(w.updatedAt()))
                .update();
        if (updated == 0) {
            jdbc.sql("""
                            INSERT INTO entrenos_carrera (id, usuario_id, nombre, plantilla, pasos, creado_en,
                                actualizado_en)
                            VALUES (:id, :user, :name, :template, CAST(:steps AS jsonb), :createdAt, :updatedAt)
                            """)
                    .param("id", w.id())
                    .param("user", w.userId())
                    .param("name", w.name())
                    .param("template", w.templateCode())
                    .param("steps", codec.groups(w.groups()))
                    .param("createdAt", Timestamp.from(w.createdAt()))
                    .param("updatedAt", Timestamp.from(w.updatedAt()))
                    .update();
        }
        return w;
    }

    @Override
    public Optional<RunWorkout> findOwned(UUID userId, UUID workoutId) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM entrenos_carrera WHERE id = :id AND usuario_id = :user")
                .param("id", workoutId)
                .param("user", userId)
                .query(this::map)
                .optional();
    }

    @Override
    public List<RunWorkout> findAll(UUID userId) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM entrenos_carrera WHERE usuario_id = :user"
                        + " ORDER BY actualizado_en DESC")
                .param("user", userId)
                .query(this::map)
                .list();
    }

    @Override
    public void delete(UUID userId, UUID workoutId) {
        jdbc.sql("DELETE FROM entrenos_carrera WHERE id = :id AND usuario_id = :user")
                .param("id", workoutId)
                .param("user", userId)
                .update();
    }

    @Override
    public void linkEvent(UUID blockId, UUID workoutId, UUID userId) {
        jdbc.sql("INSERT INTO eventos_entreno_carrera (bloque_id, entreno_carrera_id, usuario_id)"
                        + " VALUES (:block, :workout, :user)")
                .param("block", blockId)
                .param("workout", workoutId)
                .param("user", userId)
                .update();
    }

    @Override
    public Optional<UUID> workoutOfEvent(UUID userId, UUID blockId) {
        return jdbc.sql("SELECT entreno_carrera_id FROM eventos_entreno_carrera"
                        + " WHERE bloque_id = :block AND usuario_id = :user")
                .param("block", blockId)
                .param("user", userId)
                .query(UUID.class)
                .optional();
    }

    @Override
    public List<PlannedRun> findPlanned(UUID userId, Instant from, Instant to) {
        return jdbc.sql("""
                        SELECT e.bloque_id, w.id, w.nombre, b.hora_inicio, b.hora_fin
                        FROM eventos_entreno_carrera e
                        JOIN entrenos_carrera w ON w.id = e.entreno_carrera_id
                        JOIN horarios_academicos b ON b.id = e.bloque_id
                        WHERE e.usuario_id = :user AND b.completado = false
                            AND b.hora_fin > :from AND b.hora_inicio < :to
                        ORDER BY b.hora_inicio
                        """)
                .param("user", userId)
                .param("from", Timestamp.from(from))
                .param("to", Timestamp.from(to))
                .query((rs, n) -> new PlannedRun(rs.getObject("bloque_id", UUID.class),
                        rs.getObject("id", UUID.class), rs.getString("nombre"),
                        rs.getTimestamp("hora_inicio").toInstant(), rs.getTimestamp("hora_fin").toInstant()))
                .list();
    }

    private RunWorkout map(ResultSet rs, int row) throws SQLException {
        return new RunWorkout(rs.getObject("id", UUID.class), rs.getObject("usuario_id", UUID.class),
                rs.getString("nombre"), rs.getString("plantilla"), codec.groups(rs.getString("pasos")),
                rs.getTimestamp("creado_en").toInstant(), rs.getTimestamp("actualizado_en").toInstant());
    }
}
