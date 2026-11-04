package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.challenge;

import java.util.List;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training.TrainingDbValues;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.ProgressStatus;
import com.synaptixfit.domain.model.challenge.RoutineDayTarget;
import com.synaptixfit.domain.model.challenge.StudyBlockProgress;
import com.synaptixfit.domain.model.training.TrainingRewards;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Lecturas de propiedad sobre tablas de Académico ({@code asignaturas}, {@code apuntes},
 * {@code archivos_asignatura}) y Planificador ({@code entregas_examenes}, {@code horarios_academicos}),
 * y de Entrenamiento: recuento de sesiones completadas ({@code sesiones_registradas}) y días de la rutina en
 * curso ({@code dias_rutina}) para vincular tareas.
 */
@Repository
public class ChallengeReferencePersistenceAdapter implements ChallengeReferencePort {

    private final JdbcClient jdbc;

    public ChallengeReferencePersistenceAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public boolean subjectBelongsTo(UUID userId, UUID subjectId) {
        return owned("asignaturas", userId, subjectId);
    }

    @Override
    public boolean deadlineBelongsTo(UUID userId, UUID deadlineId) {
        return owned("entregas_examenes", userId, deadlineId);
    }

    @Override
    public boolean routineDayBelongsTo(UUID userId, UUID routineDayId) {
        return jdbc.sql("""
                        select count(*) from dias_rutina d
                        join semanas_rutina s on s.id = d.semana_id
                        join rutinas r on r.id = s.rutina_id
                        where d.id = :id and r.usuario_id = :user and r.eliminado_en is null
                        """)
                .param("id", routineDayId)
                .param("user", userId)
                .query(Long.class).single() > 0;
    }

    @Override
    public List<RoutineDayTarget> routineDayTargets(UUID userId) {
        String completed = TrainingDbValues.dayStatusToDb(ProgressStatus.COMPLETED);
        String skipped = TrainingDbValues.dayStatusToDb(ProgressStatus.SKIPPED);
        return jdbc.sql("""
                        select d.id, r.nombre as rutina, s.numero_semana, d.numero_dia, d.nombre as dia, d.estado,
                               (select count(*) from seleccion_de_ejercicios e where e.dia_id = d.id) as ejercicios
                        from dias_rutina d
                        join semanas_rutina s on s.id = d.semana_id
                        join rutinas r on r.id = s.rutina_id
                        where r.usuario_id = :user and r.estado = :active and r.eliminado_en is null
                        order by s.numero_semana, d.numero_dia
                        """)
                .param("user", userId)
                .param("active", TrainingDbValues.toDb(RoutineStatus.ACTIVE))
                .query((rs, n) -> {
                    String status = rs.getString("estado");
                    return new RoutineDayTarget(rs.getObject("id", UUID.class), rs.getString("rutina"),
                            rs.getInt("numero_semana"), rs.getInt("numero_dia"), rs.getString("dia"),
                            completed.equals(status) || skipped.equals(status), rs.getLong("ejercicios") > 0);
                })
                .list();
    }

    @Override
    public boolean noteBelongsTo(UUID userId, UUID noteId) {
        return owned("apuntes", userId, noteId);
    }

    @Override
    public boolean fileBelongsTo(UUID userId, UUID fileId) {
        return owned("archivos_asignatura", userId, fileId);
    }

    @Override
    public StudyBlockProgress studyBlockProgress(UUID userId, UUID milestoneId) {
        return jdbc.sql("""
                        select count(*) as total, coalesce(sum(case when completado then 1 else 0 end), 0) as done
                        from horarios_academicos where hito_id = :milestone and usuario_id = :user
                        """)
                .param("milestone", milestoneId)
                .param("user", userId)
                .query((rs, n) -> new StudyBlockProgress(rs.getInt("total"), rs.getInt("done")))
                .single();
    }

    @Override
    public int completedTrainingSessions(UUID userId, Instant from, Instant to) {
        return jdbc.sql("""
                        select count(*) from sesiones_registradas
                        where usuario_id = :user and completada_en is not null
                          and completada_en >= :from and completada_en <= :to
                          and duracion_minutos >= :minMinutes
                        """)
                .param("user", userId)
                .param("minMinutes", TrainingRewards.MIN_COUNTED_MINUTES)
                .param("from", OffsetDateTime.ofInstant(from, ZoneOffset.UTC))
                .param("to", OffsetDateTime.ofInstant(to, ZoneOffset.UTC))
                .query(Long.class).single().intValue();
    }

    /** {@code table} es siempre una constante de esta clase, nunca un dato de entrada. */
    private boolean owned(String table, UUID userId, UUID id) {
        return jdbc.sql("select count(*) from " + table + " where id = :id and usuario_id = :user")
                .param("id", id)
                .param("user", userId)
                .query(Long.class).single() > 0;
    }
}
