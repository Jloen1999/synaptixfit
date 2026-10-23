package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.planner;

import com.synaptixfit.domain.model.neuro.BiologicalSex;
import com.synaptixfit.domain.model.planner.PlannerProfile;
import com.synaptixfit.domain.model.planner.RoutineRef;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.port.output.planner.ChallengeDirectoryPort;
import com.synaptixfit.domain.port.output.planner.PlannerProfilePort;
import com.synaptixfit.domain.port.output.planner.RoutineDirectoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Lecturas del planificador sobre tablas de otros módulos (asignaturas, perfiles, rutinas, retos)
 * con {@link JdbcClient}. Solo lectura: el planificador nunca escribe en ellas.
 */
@Repository
public class PlannerDirectoryJdbcAdapter implements SubjectDirectoryPort, PlannerProfilePort, RoutineDirectoryPort,
        ChallengeDirectoryPort {

    private static final String SUBJECT_COLUMNS =
            "select id, nombre, codigo, dificultad_percibida, creditos, ics_url from asignaturas ";
    private static final String ROUTINE_COLUMNS =
            "select id, nombre, objetivo, duracion_semanas, cantidad_ejercicios from rutinas ";

    private final JdbcClient jdbc;

    public PlannerDirectoryJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    // ------------------------------------------------------------------ asignaturas

    @Override
    public Optional<SubjectRef> findOwned(UUID userId, UUID subjectId) {
        return jdbc.sql(SUBJECT_COLUMNS + "where id = :id and usuario_id = :userId")
                .param("id", subjectId).param("userId", userId)
                .query(PlannerDirectoryJdbcAdapter::subject).optional();
    }

    @Override
    public List<SubjectRef> findActive(UUID userId) {
        return jdbc.sql(SUBJECT_COLUMNS + "where usuario_id = :userId and archivado = false order by nombre")
                .param("userId", userId)
                .query(PlannerDirectoryJdbcAdapter::subject).list();
    }

    @Override
    public Map<UUID, String> namesOf(UUID userId, Collection<UUID> subjectIds) {
        Map<UUID, String> names = new HashMap<>();
        if (subjectIds.isEmpty()) {
            return names;
        }
        jdbc.sql("select id, nombre from asignaturas where usuario_id = :userId and id in (:ids)")
                .param("userId", userId).param("ids", List.copyOf(subjectIds))
                .query((ResultSet rs) -> {
                    names.put(rs.getObject("id", UUID.class), rs.getString("nombre"));
                });
        return names;
    }

    private static SubjectRef subject(ResultSet rs, int row) throws SQLException {
        return new SubjectRef(rs.getObject("id", UUID.class), rs.getString("nombre"), rs.getString("codigo"),
                rs.getInt("dificultad_percibida"), rs.getInt("creditos"), rs.getString("ics_url"));
    }

    // ------------------------------------------------------------------ perfiles

    @Override
    public Optional<PlannerProfile.Metabolic> findMetabolic(UUID userId) {
        return jdbc.sql("select peso_kg, altura_cm, edad, sexo from perfil_bienestar_usuario "
                        + "where usuario_id = :userId order by actualizado_en desc limit 1")
                .param("userId", userId)
                .query((rs, n) -> new PlannerProfile.Metabolic(rs.getDouble("peso_kg"), rs.getDouble("altura_cm"),
                        rs.getInt("edad"), sex(rs.getString("sexo"))))
                .optional();
    }

    @Override
    public Optional<PlannerProfile.Academic> findAcademic(UUID userId) {
        return jdbc.sql("select horas_objetivo_estudio_semana, fecha_inicio_clases, fecha_fin_clases "
                        + "from perfil_academico_usuario where usuario_id = :userId order by actualizado_en desc limit 1")
                .param("userId", userId)
                .query((rs, n) -> new PlannerProfile.Academic(rs.getInt("horas_objetivo_estudio_semana"),
                        date(rs.getDate("fecha_inicio_clases")), date(rs.getDate("fecha_fin_clases"))))
                .optional();
    }

    private static BiologicalSex sex(String value) {
        if ("hombre".equals(value)) {
            return BiologicalSex.MALE;
        }
        return "mujer".equals(value) ? BiologicalSex.FEMALE : BiologicalSex.OTHER;
    }

    private static LocalDate date(Date value) {
        return value == null ? null : value.toLocalDate();
    }

    // ------------------------------------------------------------------ rutinas

    @Override
    public Optional<RoutineRef> findOwnedWithDays(UUID userId, UUID routineId) {
        Optional<RoutineRef> routine = jdbc.sql(ROUTINE_COLUMNS
                        + "where id = :id and usuario_id = :userId and eliminado_en is null")
                .param("id", routineId).param("userId", userId)
                .query((rs, n) -> routine(rs, List.of())).optional();
        if (routine.isEmpty()) {
            return routine;
        }
        List<RoutineRef.Day> days = jdbc.sql("select d.id, d.semana_id, s.numero_semana, d.numero_dia, d.nombre "
                        + "from dias_rutina d join semanas_rutina s on s.id = d.semana_id "
                        + "where s.rutina_id = :routineId order by s.numero_semana, d.numero_dia")
                .param("routineId", routineId)
                .query((rs, n) -> new RoutineRef.Day(rs.getObject("id", UUID.class),
                        rs.getObject("semana_id", UUID.class), rs.getInt("numero_semana"), rs.getInt("numero_dia"),
                        rs.getString("nombre")))
                .list();
        RoutineRef r = routine.get();
        return Optional.of(new RoutineRef(r.id(), r.name(), r.goal(), r.weeks(), r.exerciseCount(), days));
    }

    @Override
    public List<RoutineRef> findActive(UUID userId, int limit) {
        return jdbc.sql(ROUTINE_COLUMNS + "where usuario_id = :userId and estado = 'activo' and eliminado_en is null "
                        + "order by creado_en desc limit :limit")
                .param("userId", userId).param("limit", limit)
                .query((rs, n) -> routine(rs, List.of())).list();
    }

    private static RoutineRef routine(ResultSet rs, List<RoutineRef.Day> days) throws SQLException {
        return new RoutineRef(rs.getObject("id", UUID.class), rs.getString("nombre"), rs.getString("objetivo"),
                rs.getInt("duracion_semanas"), rs.getInt("cantidad_ejercicios"), days);
    }

    // ------------------------------------------------------------------ retos

    @Override
    public boolean ownsChallenge(UUID userId, UUID challengeId) {
        return jdbc.sql("select count(*) from retos where id = :id and usuario_id = :userId")
                .param("id", challengeId).param("userId", userId)
                .query(Long.class).single() > 0;
    }

    @Override
    public boolean ownsMilestone(UUID userId, UUID milestoneId) {
        return jdbc.sql("select count(*) from hitos_de_reto h join retos r on r.id = h.reto_id "
                        + "where h.id = :id and r.usuario_id = :userId")
                .param("id", milestoneId).param("userId", userId)
                .query(Long.class).single() > 0;
    }
}
