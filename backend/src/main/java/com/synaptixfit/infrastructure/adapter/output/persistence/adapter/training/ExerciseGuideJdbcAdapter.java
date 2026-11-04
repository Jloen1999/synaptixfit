package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.training.ExerciseNote;
import com.synaptixfit.domain.model.training.ExerciseTips;
import com.synaptixfit.domain.port.output.training.ExerciseNoteRepositoryPort;
import com.synaptixfit.domain.port.output.training.ExerciseTipsRepositoryPort;
import java.sql.Array;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link ExerciseTipsRepositoryPort} y {@link ExerciseNoteRepositoryPort} sobre
 * {@code consejos_ejercicio} y {@code notas_ejercicio} (V1032). Las notas se sustituyen con borrar e insertar
 * (SQL estándar, sin {@code ON CONFLICT}).
 */
@Component
public class ExerciseGuideJdbcAdapter implements ExerciseTipsRepositoryPort, ExerciseNoteRepositoryPort {

    private final JdbcClient jdbc;

    public ExerciseGuideJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<ExerciseTips> find(UUID exerciseId, String language) {
        return jdbc.sql("SELECT claves, errores FROM consejos_ejercicio WHERE ejercicio_id = :id AND idioma = :lang")
                .param("id", exerciseId)
                .param("lang", language)
                .query((rs, n) -> new ExerciseTips(lines(rs, "claves"), lines(rs, "errores")))
                .optional();
    }

    @Override
    public Optional<ExerciseNote> find(UUID userId, UUID exerciseId) {
        return jdbc.sql("SELECT texto, actualizado_en FROM notas_ejercicio WHERE usuario_id = :user"
                        + " AND ejercicio_id = :id")
                .param("user", userId)
                .param("id", exerciseId)
                .query((rs, n) -> new ExerciseNote(exerciseId, rs.getString("texto"),
                        rs.getTimestamp("actualizado_en").toInstant()))
                .optional();
    }

    @Override
    public void save(UUID userId, ExerciseNote note) {
        delete(userId, note.exerciseId());
        jdbc.sql("INSERT INTO notas_ejercicio (usuario_id, ejercicio_id, texto, actualizado_en)"
                        + " VALUES (:user, :id, :text, :at)")
                .param("user", userId)
                .param("id", note.exerciseId())
                .param("text", note.text())
                .param("at", Timestamp.from(note.updatedAt()))
                .update();
    }

    @Override
    public void delete(UUID userId, UUID exerciseId) {
        jdbc.sql("DELETE FROM notas_ejercicio WHERE usuario_id = :user AND ejercicio_id = :id")
                .param("user", userId)
                .param("id", exerciseId)
                .update();
    }

    private static List<String> lines(ResultSet rs, String column) throws SQLException {
        Array array = rs.getArray(column);
        return array == null ? List.of() : Arrays.stream((Object[]) array.getArray()).map(String::valueOf).toList();
    }
}
