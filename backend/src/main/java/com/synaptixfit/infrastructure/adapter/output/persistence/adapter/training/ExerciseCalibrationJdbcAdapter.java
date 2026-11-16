package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.training.load.CalibrationAnswer;
import com.synaptixfit.domain.model.training.load.CalibrationStep;
import com.synaptixfit.domain.model.training.load.ExerciseCalibrationRecord;
import com.synaptixfit.domain.port.output.training.ExerciseCalibrationRepositoryPort;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link ExerciseCalibrationRepositoryPort} sobre {@code calibraciones_ejercicio} (V1072, ADR 0054). Una
 * respuesta por hueco de ejercicio y sesión: volver a responder borra la anterior y guarda la nueva (SQL estándar,
 * sin «upsert» propio del motor).
 */
@Component
public class ExerciseCalibrationJdbcAdapter implements ExerciseCalibrationRepositoryPort {

    private final JdbcClient jdbc;

    public ExerciseCalibrationJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public ExerciseCalibrationRecord save(ExerciseCalibrationRecord c) {
        jdbc.sql("DELETE FROM calibraciones_ejercicio WHERE sesion_id = :session"
                        + " AND ejercicio_seleccionado_id = :planned")
                .param("session", c.sessionId())
                .param("planned", c.plannedExerciseId())
                .update();
        jdbc.sql("INSERT INTO calibraciones_ejercicio (id, usuario_id, sesion_id, ejercicio_seleccionado_id,"
                        + " ejercicio_id, numero_serie, respuesta, peso_kg, paso, peso_siguiente_kg, respondida_en)"
                        + " VALUES (:id, :user, :session, :planned, :exercise, :set, :answer, :weight, :step, :next,"
                        + " :at)")
                .param("id", c.id())
                .param("user", c.userId())
                .param("session", c.sessionId())
                .param("planned", c.plannedExerciseId())
                .param("exercise", c.exerciseId())
                .param("set", c.setNumber())
                .param("answer", c.answer().name())
                .param("weight", c.weightKg())
                .param("step", c.step().name())
                .param("next", c.nextWeightKg())
                .param("at", Timestamp.from(c.answeredAt()))
                .update();
        return c;
    }

    @Override
    public List<ExerciseCalibrationRecord> findBySession(UUID sessionId) {
        return jdbc.sql("SELECT id, usuario_id, sesion_id, ejercicio_seleccionado_id, ejercicio_id, numero_serie,"
                        + " respuesta, peso_kg, paso, peso_siguiente_kg, respondida_en FROM calibraciones_ejercicio"
                        + " WHERE sesion_id = :session ORDER BY respondida_en")
                .param("session", sessionId)
                .query((rs, n) -> new ExerciseCalibrationRecord(rs.getObject("id", UUID.class),
                        rs.getObject("usuario_id", UUID.class), rs.getObject("sesion_id", UUID.class),
                        rs.getObject("ejercicio_seleccionado_id", UUID.class), rs.getObject("ejercicio_id", UUID.class),
                        rs.getInt("numero_serie"), CalibrationAnswer.valueOf(rs.getString("respuesta")),
                        number(rs.getBigDecimal("peso_kg")), CalibrationStep.valueOf(rs.getString("paso")),
                        number(rs.getBigDecimal("peso_siguiente_kg")),
                        rs.getTimestamp("respondida_en").toInstant()))
                .list();
    }

    private static Double number(BigDecimal value) {
        return value == null ? null : value.doubleValue();
    }
}
