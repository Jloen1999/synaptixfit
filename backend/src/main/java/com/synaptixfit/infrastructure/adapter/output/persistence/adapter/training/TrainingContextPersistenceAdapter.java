package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.generation.AcademicContext;
import com.synaptixfit.domain.model.training.generation.PhysiologicalContext;
import com.synaptixfit.domain.model.training.generation.TrainingProfile;
import com.synaptixfit.domain.port.output.training.TrainingContextPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training.TrainingDbValues;
import java.sql.Array;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.DayOfWeek;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Lecturas (solo SQL, sin entidades) de tablas de otros módulos: perfil de bienestar, historial de
 * peso y de objetivos (perfil), horarios, entregas y carga académica (planificador) y racha/nivel
 * (cuenta). Las semanas van de lunes a domingo en la zona de la app ({@code synaptixfit.insights.default-zone}).
 */
@Repository
public class TrainingContextPersistenceAdapter implements TrainingContextPort {

    private final JdbcClient jdbc;
    private final ZoneId zone;

    public TrainingContextPersistenceAdapter(JdbcClient jdbc,
                                             @Value("${synaptixfit.insights.default-zone:Europe/Madrid}") String zone) {
        this.jdbc = jdbc;
        this.zone = ZoneId.of(zone);
    }

    @Override
    public Optional<Double> bodyWeightKg(UUID userId) {
        return jdbc.sql("SELECT peso_kg FROM perfil_bienestar_usuario WHERE usuario_id = :u LIMIT 1")
                .param("u", userId).query(Double.class).optional();
    }

    @Override
    public Optional<TrainingProfile> profile(UUID userId) {
        return jdbc.sql("SELECT edad, sexo, peso_kg, altura_cm, imc, nivel_actividad, objetivo_principal,"
                        + " equipamiento_disponible, dias_disponibles_semana, minutos_por_sesion, dias_disponibles"
                        + " FROM perfil_bienestar_usuario WHERE usuario_id = :u LIMIT 1")
                .param("u", userId)
                .query((rs, n) -> new TrainingProfile(rs.getInt("edad"), rs.getString("sexo"), rs.getDouble("peso_kg"),
                        rs.getDouble("altura_cm"), rs.getDouble("imc"),
                        TrainingDbValues.activityLevel(rs.getString("nivel_actividad")),
                        TrainingGoal.fromLabelOrDefault(rs.getString("objetivo_principal")),
                        strings(rs.getArray("equipamiento_disponible")), rs.getInt("dias_disponibles_semana"),
                        rs.getInt("minutos_por_sesion"), integers(rs.getArray("dias_disponibles"))))
                .optional();
    }

    @Override
    public AcademicContext academicContext(UUID userId, LocalDate today) {
        LocalDate monday = today.with(DayOfWeek.MONDAY);
        OffsetDateTime from = monday.atStartOfDay(zone).toOffsetDateTime();
        OffsetDateTime to = from.plusDays(7);

        record Load(double planned, double real, double stress, double sleep) {
        }
        Load load = jdbc.sql("SELECT horas_estudio_planeadas, horas_estudio_reales, nivel_estres, horas_sueno_promedio"
                        + " FROM carga_academica_semanal WHERE usuario_id = :u AND semana_inicio = :monday")
                .param("u", userId).param("monday", monday)
                .query((rs, n) -> new Load(rs.getDouble(1), rs.getDouble(2), rs.getDouble(3), rs.getDouble(4)))
                .optional().orElse(new Load(0, 0, 5, 7));

        // Se traen los intervalos y se suman en Java: restar fechas y truncar a día son funciones
        // distintas en cada motor (EXTRACT(EPOCH ...) solo existe en PostgreSQL).
        record Interval(Instant start, Instant end) {
        }
        List<Interval> blocks = jdbc.sql("SELECT hora_inicio, hora_fin FROM horarios_academicos"
                        + " WHERE usuario_id = :u AND tipo_actividad IN (:types) AND completado = true"
                        + " AND hora_inicio >= :from AND hora_inicio < :to")
                .param("u", userId).param("from", from).param("to", to)
                .param("types", ActivityType.codesWhere(ActivityType::countsAsStudy))
                .query((rs, n) -> new Interval(rs.getObject(1, OffsetDateTime.class).toInstant(),
                        rs.getObject(2, OffsetDateTime.class).toInstant()))
                .list();
        double studyHours = blocks.stream()
                .mapToDouble(b -> Math.max(0, Duration.between(b.start(), b.end()).getSeconds()) / 3600.0).sum();
        int studyDays = (int) blocks.stream().map(b -> LocalDate.ofInstant(b.start(), zone)).distinct().count();

        record Deadlines(int total, int done) {
        }
        Deadlines deadlines = jdbc.sql("SELECT COUNT(*), COALESCE(SUM(CASE WHEN esta_completado THEN 1 ELSE 0 END), 0)"
                        + " FROM entregas_examenes"
                        + " WHERE usuario_id = :u AND fecha_limite >= :from AND fecha_limite < :to")
                .param("u", userId).param("from", from).param("to", to)
                .query((rs, n) -> new Deadlines(rs.getInt(1), rs.getInt(2))).single();

        OffsetDateTime startOfToday = today.atStartOfDay().atOffset(ZoneOffset.UTC);
        Integer daysToExam = jdbc.sql("SELECT MIN(fecha_limite) FROM entregas_examenes"
                        + " WHERE usuario_id = :u AND esta_completado = false AND fecha_limite >= :now")
                .param("u", userId).param("now", startOfToday)
                .query((rs, n) -> {
                    Timestamp t = rs.getTimestamp(1);
                    return t == null ? null
                            : (int) ChronoUnit.DAYS.between(today, LocalDate.ofInstant(t.toInstant(), ZoneOffset.UTC));
                }).optional().orElse(null);

        // Carga cognitiva y ACWR no se leen aquí: la caché de indicadores puede ser de otro día; el
        // servicio los pide recalculados a los casos de uso de indicadores (AcademicContext.withInsights).
        return new AcademicContext(load.planned(), Math.max(load.real(), studyHours),
                Math.max(1, Math.min(10, load.stress())), deadlines.total(), deadlines.done(), studyDays,
                load.sleep(), daysToExam, null, null);
    }

    @Override
    public PhysiologicalContext physiologicalContext(UUID userId, LocalDate today) {
        record Account(int streak, int level) {
        }
        Account account = jdbc.sql("SELECT racha_actual, nivel FROM usuarios WHERE id = :u").param("u", userId)
                .query((rs, n) -> new Account(rs.getInt(1), rs.getInt(2))).optional().orElse(new Account(1, 1));
        Double current = jdbc.sql("SELECT peso_kg FROM historial_peso WHERE usuario_id = :u ORDER BY registrado_en DESC LIMIT 1")
                .param("u", userId).query(Double.class).optional().orElse(null);
        Double weekAgo = jdbc.sql("SELECT peso_kg FROM historial_peso WHERE usuario_id = :u AND registrado_en <= :limit"
                        + " ORDER BY registrado_en DESC LIMIT 1")
                .param("u", userId).param("limit", today.minusDays(7).atStartOfDay().atOffset(ZoneOffset.UTC))
                .query(Double.class).optional().orElse(null);
        return new PhysiologicalContext(current, weekAgo, account.streak(), account.level());
    }

    @Override
    public Optional<GoalChange> latestGoalChange(UUID userId) {
        return jdbc.sql("SELECT objetivo, objetivo_anterior, fecha_inicio FROM historial_objetivos WHERE usuario_id = :u"
                        + " ORDER BY fecha_inicio DESC, creado_en DESC LIMIT 1")
                .param("u", userId)
                .query((rs, n) -> new GoalChange(TrainingGoal.fromLabel(rs.getString("objetivo_anterior")).orElse(null),
                        TrainingGoal.fromLabelOrDefault(rs.getString("objetivo")),
                        rs.getObject("fecha_inicio", LocalDate.class)))
                .optional();
    }

    private static List<String> strings(Array array) throws SQLException {
        if (array == null) {
            return List.of();
        }
        Object v = array.getArray();
        return v instanceof String[] s ? Arrays.asList(s) : List.of();
    }

    private static List<Integer> integers(Array array) throws SQLException {
        if (array == null) {
            return List.of();
        }
        Object v = array.getArray();
        return v instanceof Integer[] i ? Arrays.asList(i) : List.of();
    }
}
