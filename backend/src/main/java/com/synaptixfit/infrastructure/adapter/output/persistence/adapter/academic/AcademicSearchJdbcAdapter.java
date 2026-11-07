package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.AcademicSearch;
import com.synaptixfit.domain.port.output.academic.AcademicSearchPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.SqlLike;
import java.sql.Timestamp;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link AcademicSearchPort} con {@link JdbcClient}: asignaturas, apuntes y archivos (Académico) y entregas
 * (tabla del planificador, solo lectura). Compara sin mayúsculas ni tildes con {@link SqlLike#containsFolded}.
 */
@Component
public class AcademicSearchJdbcAdapter implements AcademicSearchPort {

    private final JdbcClient jdbc;

    public AcademicSearchJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public List<AcademicSearch.Hit> subjects(UUID userId, String folded, int limit) {
        return jdbc.sql("SELECT id, nombre, codigo FROM asignaturas WHERE usuario_id = :u AND ("
                        + SqlLike.containsFolded("nombre", "p") + " OR " + SqlLike.containsFolded("codigo", "p")
                        + " OR " + SqlLike.containsFolded("docente", "p") + ")"
                        + " ORDER BY archivado, nombre LIMIT :limit")
                .param("u", userId).param("p", SqlLike.contains(folded)).param("limit", limit)
                .query((rs, n) -> new AcademicSearch.Hit(AcademicSearch.Kind.SUBJECT, rs.getObject("id", UUID.class),
                        rs.getString("nombre"), rs.getString("codigo"), rs.getObject("id", UUID.class), null, false))
                .list();
    }

    @Override
    public List<AcademicSearch.Hit> notes(UUID userId, String folded, int limit) {
        return jdbc.sql("SELECT n.id, n.titulo, n.asignatura_id, a.nombre AS asignatura FROM apuntes n"
                        + " LEFT JOIN asignaturas a ON a.id = n.asignatura_id"
                        + " WHERE n.usuario_id = :u AND (" + SqlLike.containsFolded("n.titulo", "p") + " OR "
                        + SqlLike.containsFolded("n.contenido", "p") + ")"
                        + " ORDER BY n.actualizado_en DESC LIMIT :limit")
                .param("u", userId).param("p", SqlLike.contains(folded)).param("limit", limit)
                .query((rs, n) -> new AcademicSearch.Hit(AcademicSearch.Kind.NOTE, rs.getObject("id", UUID.class),
                        rs.getString("titulo"), rs.getString("asignatura"), rs.getObject("asignatura_id", UUID.class),
                        null, false))
                .list();
    }

    @Override
    public List<AcademicSearch.Hit> files(UUID userId, String folded, int limit) {
        return jdbc.sql("SELECT f.id, f.nombre_archivo, f.asignatura_id, a.nombre AS asignatura"
                        + " FROM archivos_asignatura f JOIN asignaturas a ON a.id = f.asignatura_id"
                        + " WHERE f.usuario_id = :u AND " + SqlLike.containsFolded("f.nombre_archivo", "p")
                        + " ORDER BY f.creado_en DESC LIMIT :limit")
                .param("u", userId).param("p", SqlLike.contains(folded)).param("limit", limit)
                .query((rs, n) -> new AcademicSearch.Hit(AcademicSearch.Kind.FILE, rs.getObject("id", UUID.class),
                        rs.getString("nombre_archivo"), rs.getString("asignatura"),
                        rs.getObject("asignatura_id", UUID.class), null, false))
                .list();
    }

    @Override
    public List<AcademicSearch.Hit> deadlines(UUID userId, String folded, int limit) {
        return jdbc.sql("SELECT e.id, e.titulo, e.tipo, e.fecha_limite, e.asignatura_id, a.nombre AS asignatura"
                        + " FROM entregas_examenes e LEFT JOIN asignaturas a ON a.id = e.asignatura_id"
                        + " WHERE e.usuario_id = :u AND e.esta_completado = FALSE AND ("
                        + SqlLike.containsFolded("e.titulo", "p") + " OR " + SqlLike.containsFolded("a.nombre", "p")
                        + ") ORDER BY e.fecha_limite LIMIT :limit")
                .param("u", userId).param("p", SqlLike.contains(folded)).param("limit", limit)
                .query((rs, n) -> {
                    Timestamp due = rs.getTimestamp("fecha_limite");
                    return new AcademicSearch.Hit(AcademicSearch.Kind.DEADLINE, rs.getObject("id", UUID.class),
                            rs.getString("titulo"), rs.getString("asignatura"),
                            rs.getObject("asignatura_id", UUID.class), due == null ? null : due.toInstant(),
                            "examen".equals(rs.getString("tipo")));
                })
                .list();
    }
}
