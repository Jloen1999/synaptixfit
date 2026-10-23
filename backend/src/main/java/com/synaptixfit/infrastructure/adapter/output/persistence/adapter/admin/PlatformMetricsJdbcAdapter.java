package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.admin;

import com.synaptixfit.domain.model.admin.AdminActivityAggregation.UserActivity;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.UserFocus;
import com.synaptixfit.domain.model.admin.PlatformCounts;
import com.synaptixfit.domain.port.output.admin.PlatformMetricsQueryPort;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link PlatformMetricsQueryPort} con consultas planas (recuentos y filas de un periodo).
 * Qué es un usuario activo y cómo se agrupa por día (UTC) lo decide {@code AdminActivityAggregation}
 * en {@code AdminMetricsService}.
 */
@Repository
public class PlatformMetricsJdbcAdapter implements PlatformMetricsQueryPort {

    private static final String COUNTS = """
            SELECT
              (SELECT count(*) FROM usuarios WHERE eliminado_en IS NULL) AS total_usuarios,
              (SELECT count(*) FROM rutinas WHERE eliminado_en IS NULL AND estado = 'activo') AS rutinas_activas,
              (SELECT count(*) FROM retos WHERE esta_completado = false AND fecha_fin >= :now) AS retos_activos,
              (SELECT count(*) FROM actividades_sociales WHERE reportado = true) AS posts_reportados,
              (SELECT count(*) FROM comentarios_feed WHERE reportado = true AND eliminado = false) AS comentarios_reportados,
              (SELECT count(*) FROM usuarios WHERE is_shadowbanned = true AND eliminado_en IS NULL) AS shadowbaneados
            """;

    private final JdbcClient jdbc;

    public PlatformMetricsJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public PlatformCounts counts(Instant now) {
        return jdbc.sql(COUNTS)
                .param("now", JdbcValues.param(now))
                .query((rs, n) -> new PlatformCounts(rs.getLong("total_usuarios"), rs.getLong("rutinas_activas"),
                        rs.getLong("retos_activos"), rs.getLong("posts_reportados"),
                        rs.getLong("comentarios_reportados"), rs.getLong("shadowbaneados")))
                .single();
    }

    @Override
    public List<Instant> signups(Instant from, Instant to) {
        return jdbc.sql("SELECT creado_en FROM usuarios WHERE creado_en >= :fromTs AND creado_en < :toTs")
                .param("fromTs", JdbcValues.param(from)).param("toTs", JdbcValues.param(to))
                .query((rs, n) -> JdbcValues.instant(rs, "creado_en")).list();
    }

    @Override
    public List<UserActivity> completedTrainingSessions(Instant from, Instant to) {
        return jdbc.sql("""
                        SELECT usuario_id, completada_en FROM sesiones_registradas
                        WHERE completada_en >= :fromTs AND completada_en < :toTs
                        """)
                .param("fromTs", JdbcValues.param(from)).param("toTs", JdbcValues.param(to))
                .query((rs, n) -> new UserActivity(JdbcValues.uuid(rs, "usuario_id"), JdbcValues.instant(rs, "completada_en")))
                .list();
    }

    @Override
    public List<UserActivity> completedBlocks(Instant from, Instant to) {
        return jdbc.sql("""
                        SELECT usuario_id, hora_inicio FROM horarios_academicos
                        WHERE completado = true AND hora_inicio >= :fromTs AND hora_inicio < :toTs
                        """)
                .param("fromTs", JdbcValues.param(from)).param("toTs", JdbcValues.param(to))
                .query((rs, n) -> new UserActivity(JdbcValues.uuid(rs, "usuario_id"), JdbcValues.instant(rs, "hora_inicio")))
                .list();
    }

    @Override
    public List<UserFocus> focusSessions(LocalDate from, LocalDate to) {
        return jdbc.sql("""
                        SELECT usuario_id, fecha, duracion_minutos FROM sesiones_focus
                        WHERE fecha >= :fromDay AND fecha <= :toDay
                        """)
                .param("fromDay", from).param("toDay", to)
                .query((rs, n) -> new UserFocus(JdbcValues.uuid(rs, "usuario_id"), JdbcValues.date(rs, "fecha"),
                        rs.getInt("duracion_minutos")))
                .list();
    }
}
