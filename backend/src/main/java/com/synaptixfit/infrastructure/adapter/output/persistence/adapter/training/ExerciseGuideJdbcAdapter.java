package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.training.ExerciseNote;
import com.synaptixfit.domain.model.training.ExerciseTips;
import com.synaptixfit.domain.model.training.MediaCredit;
import com.synaptixfit.domain.port.output.training.ExerciseMediaCreditRepositoryPort;
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
 * Implementa {@link ExerciseTipsRepositoryPort}, {@link ExerciseNoteRepositoryPort} y
 * {@link ExerciseMediaCreditRepositoryPort} sobre {@code consejos_ejercicio}, {@code notas_ejercicio} (V1032) y
 * {@code creditos_medios_ejercicio} (V1077). Las notas se sustituyen con borrar e insertar
 * (SQL estándar, sin {@code ON CONFLICT}).
 */
@Component
public class ExerciseGuideJdbcAdapter implements ExerciseTipsRepositoryPort, ExerciseNoteRepositoryPort,
        ExerciseMediaCreditRepositoryPort {

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
    public List<MediaCredit> findByExercise(UUID exerciseId) {
        // La foto primero y después el vídeo, como promete el puerto (no por casualidad alfabética).
        return jdbc.sql("SELECT tipo, fuente, licencia, licencia_url, autor, obra_url FROM creditos_medios_ejercicio"
                        + " WHERE ejercicio_id = :id ORDER BY CASE tipo WHEN 'FOTO' THEN 0 ELSE 1 END")
                .param("id", exerciseId)
                .query((rs, n) -> new MediaCredit(kind(rs.getString("tipo")), rs.getString("fuente"),
                        rs.getString("licencia"), rs.getString("licencia_url"), rs.getString("autor"),
                        rs.getString("obra_url")))
                .list();
    }

    /** La columna solo admite FOTO y VIDEO (CHECK de V1077): otro valor es un fallo de datos, no una foto. */
    private static MediaCredit.Kind kind(String tipo) {
        return switch (tipo) {
            case "FOTO" -> MediaCredit.Kind.PHOTO;
            case "VIDEO" -> MediaCredit.Kind.VIDEO;
            default -> throw new IllegalStateException("Tipo de medio desconocido: " + tipo);
        };
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

    /**
     * Crea o sustituye la nota en una sola sentencia. En PostgreSQL una clave duplicada aborta la
     * transacción, así que «insertar y, si falla, actualizar» no sirve: dos guardados seguidos darían
     * error. Propio de PostgreSQL: listado en {@code database_portability.md}.
     */
    @Override
    public void save(UUID userId, ExerciseNote note) {
        jdbc.sql("INSERT INTO notas_ejercicio (usuario_id, ejercicio_id, texto, actualizado_en)"
                        + " VALUES (:user, :id, :text, :at)"
                        + " ON CONFLICT (usuario_id, ejercicio_id)"
                        + " DO UPDATE SET texto = EXCLUDED.texto, actualizado_en = EXCLUDED.actualizado_en")
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
