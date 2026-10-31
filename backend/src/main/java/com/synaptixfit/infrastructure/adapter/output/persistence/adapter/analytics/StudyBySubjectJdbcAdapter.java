package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.analytics;

import com.synaptixfit.domain.model.analytics.StudyBySubject;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.port.output.analytics.StudyBySubjectSourcePort;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link StudyBySubjectSourcePort} leyendo {@code asignaturas}, {@code horarios_academicos} y
 * {@code registros_repaso_srs} (de otros módulos, solo lectura, SQL estándar). Las sumas y el veredicto los hace
 * el dominio.
 */
@Repository
public class StudyBySubjectJdbcAdapter implements StudyBySubjectSourcePort {

    private final JdbcClient jdbc;

    public StudyBySubjectJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Map<UUID, String> activeSubjects(UUID userId) {
        Map<UUID, String> names = new LinkedHashMap<>();
        jdbc.sql("""
                        SELECT id, nombre FROM asignaturas
                        WHERE usuario_id = :u AND (archivado IS NULL OR archivado = FALSE)
                        ORDER BY nombre
                        """)
                .param("u", userId)
                .query((rs, i) -> names.put(rs.getObject("id", UUID.class), rs.getString("nombre")))
                .list();
        return names;
    }

    @Override
    public List<StudyBySubject.StudyBlock> completedStudyBlocks(UUID userId, Instant from, Instant to) {
        return jdbc.sql("""
                        SELECT asignatura_id, hora_inicio, hora_fin FROM horarios_academicos
                        WHERE usuario_id = :u AND completado = TRUE AND tipo_actividad IN (:types)
                          AND hora_inicio >= :from AND hora_inicio < :to
                        """)
                .param("u", userId)
                .param("types", ActivityType.codesWhere(t -> t == ActivityType.STUDY || t == ActivityType.REVIEW))
                .param("from", Timestamp.from(from))
                .param("to", Timestamp.from(to))
                .query((rs, i) -> new StudyBySubject.StudyBlock(rs.getObject("asignatura_id", UUID.class),
                        rs.getTimestamp("hora_inicio").toInstant(), rs.getTimestamp("hora_fin").toInstant()))
                .list();
    }

    @Override
    public List<StudyBySubject.Review> reviews(UUID userId, Instant from, Instant to) {
        return jdbc.sql("""
                        SELECT m.asignatura_id, r.q_real FROM registros_repaso_srs r
                        JOIN materiales_estudio m ON m.id = r.material_estudio_id
                        WHERE m.usuario_id = :u AND r.fecha_repaso >= :from AND r.fecha_repaso < :to
                        """)
                .param("u", userId)
                .param("from", Timestamp.from(from))
                .param("to", Timestamp.from(to))
                .query((rs, i) -> new StudyBySubject.Review(rs.getObject("asignatura_id", UUID.class),
                        rs.getInt("q_real")))
                .list();
    }
}
