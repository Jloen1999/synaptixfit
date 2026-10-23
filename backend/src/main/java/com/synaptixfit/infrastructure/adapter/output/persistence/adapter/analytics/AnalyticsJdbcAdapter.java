package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.analytics;

import com.synaptixfit.domain.model.academic.MasteryState;
import com.synaptixfit.domain.model.analytics.StudyWeekSummary;
import com.synaptixfit.domain.model.analytics.WeeklyStudyLoad;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric.CompletedSession;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric;
import com.synaptixfit.domain.port.output.analytics.AnalyticsSourcePort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights.JdbcRows;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicDbCodes;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Lee {@code sesiones_registradas} (entrenamiento), {@code carga_academica_semanal} (planificador) y, para
 * «Tu estudio», recuentos de Pomodoro, bloques, repasos y simulacros.
 * Solo trae filas: la zona y el agregado semanal ({@link WeeklyTrainingMetric#byWeek}) los aplica
 * el caso de uso.
 */
@Repository
public class AnalyticsJdbcAdapter implements AnalyticsSourcePort {

    private final JdbcClient jdbc;

    public AnalyticsJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public List<CompletedSession> completedTrainingSessions(UUID userId, Instant from) {
        return jdbc.sql("""
                        SELECT completada_en, duracion_minutos, calorias_quemadas, rpe
                        FROM sesiones_registradas
                        WHERE usuario_id = :u AND completada_en IS NOT NULL AND completada_en >= :from
                        """)
                .param("u", userId)
                .param("from", JdbcRows.param(from))
                .query((rs, n) -> new CompletedSession(JdbcRows.instant(rs, "completada_en"),
                        rs.getInt("duracion_minutos"), JdbcRows.decimal(rs, "calorias_quemadas"),
                        JdbcRows.integer(rs, "rpe")))
                .list();
    }

    @Override
    public List<WeeklyStudyLoad> weeklyStudyLoads(UUID userId, LocalDate fromWeek) {
        return jdbc.sql("""
                        SELECT semana_inicio, max(horas_estudio_reales) AS horas
                        FROM carga_academica_semanal
                        WHERE usuario_id = :u AND semana_inicio >= :from
                        GROUP BY semana_inicio
                        ORDER BY semana_inicio
                        """)
                .param("u", userId).param("from", fromWeek)
                .query((rs, n) -> new WeeklyStudyLoad(JdbcRows.date(rs, "semana_inicio"), rs.getDouble("horas")))
                .list();
    }

    @Override
    public StudyWeekSummary.Counts studyCounts(UUID userId, Instant from, Instant to, LocalDate fromDay,
                                               LocalDate toDay, List<String> studyBlockCodes, Instant now) {
        return jdbc.sql("""
                        SELECT
                          (SELECT COALESCE(SUM(duracion_minutos), 0) FROM sesiones_focus
                            WHERE usuario_id = :u AND completada = true AND tipo_fase = 'focus'
                              AND fecha >= :fromDay AND fecha < :toDay) AS focus_minutes,
                          (SELECT COUNT(*) FROM sesiones_focus
                            WHERE usuario_id = :u AND completada = true AND tipo_fase = 'focus'
                              AND fecha >= :fromDay AND fecha < :toDay) AS focus_sessions,
                          (SELECT COUNT(*) FROM horarios_academicos
                            WHERE usuario_id = :u AND tipo_actividad IN (:codes)
                              AND hora_inicio >= :from AND hora_inicio < :to) AS blocks_planned,
                          (SELECT COALESCE(SUM(CASE WHEN completado THEN 1 ELSE 0 END), 0) FROM horarios_academicos
                            WHERE usuario_id = :u AND tipo_actividad IN (:codes)
                              AND hora_inicio >= :from AND hora_inicio < :to) AS blocks_completed,
                          (SELECT COUNT(*) FROM registros_repaso_srs r
                            JOIN materiales_estudio m ON m.id = r.material_estudio_id
                            WHERE m.usuario_id = :u AND r.fecha_repaso >= :from AND r.fecha_repaso < :to) AS reviews,
                          (SELECT COUNT(*) FROM test_sessions
                            WHERE usuario_id = :u AND status = 'completed'
                              AND completado_en >= :from AND completado_en < :to) AS tests,
                          (SELECT COALESCE(SUM(score), 0) FROM test_sessions
                            WHERE usuario_id = :u AND status = 'completed'
                              AND completado_en >= :from AND completado_en < :to) AS test_correct,
                          (SELECT COALESCE(SUM(total_preguntas), 0) FROM test_sessions
                            WHERE usuario_id = :u AND status = 'completed'
                              AND completado_en >= :from AND completado_en < :to) AS test_questions,
                          (SELECT COUNT(*) FROM materiales_estudio
                            WHERE usuario_id = :u AND siguiente_repaso_en IS NOT NULL
                              AND siguiente_repaso_en <= :now AND estado_dominio <> :abandoned) AS reviews_due
                        """)
                .param("u", userId)
                .param("from", JdbcRows.param(from))
                .param("to", JdbcRows.param(to))
                .param("now", JdbcRows.param(now))
                .param("fromDay", fromDay)
                .param("toDay", toDay)
                .param("codes", studyBlockCodes)
                // Igual que la cola de repasos: los materiales abandonados no cuentan como pendientes.
                .param("abandoned", AcademicDbCodes.mastery(MasteryState.ABANDONED))
                .query((rs, n) -> new StudyWeekSummary.Counts(rs.getInt("focus_minutes"), rs.getInt("focus_sessions"),
                        rs.getInt("blocks_planned"), rs.getInt("blocks_completed"), rs.getInt("reviews"),
                        rs.getInt("tests"), rs.getInt("test_correct"), rs.getInt("test_questions"),
                        rs.getInt("reviews_due")))
                .single();
    }
}
