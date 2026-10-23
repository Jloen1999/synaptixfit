package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.CatalogSubject;
import com.synaptixfit.domain.port.output.academic.AcademicCatalogPort;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/** Lee el catálogo académico (tablas del módulo Perfil y catálogo) con SQL de solo lectura. */
@Repository
public class AcademicCatalogJdbcAdapter implements AcademicCatalogPort {

    private static final String COLUMNS =
            "ac.id, ac.carrera_id, ac.nombre, ac.curso, ac.semestre, ac.caracter, ac.creditos, ac.horas, "
                    + "ac.url_guia_docente, ac.codigo";

    private final JdbcClient jdbc;

    public AcademicCatalogJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public List<CatalogSubject> findByIds(Collection<UUID> ids) {
        if (ids.isEmpty()) {
            return List.of();
        }
        return jdbc.sql("SELECT " + COLUMNS + " FROM asignaturas_catalogo ac WHERE ac.id IN (:ids)")
                .param("ids", ids)
                .query(AcademicCatalogJdbcAdapter::map)
                .list();
    }

    @Override
    public List<CatalogSubject> findForUserDegrees(UUID userId) {
        String sql = """
                WITH propias AS (
                    SELECT carrera_id FROM usuario_carreras WHERE usuario_id = :userId
                ), por_perfil AS (
                    SELECT c.id AS carrera_id
                    FROM carreras c JOIN perfil_academico_usuario p ON p.carrera = c.nombre
                    WHERE p.usuario_id = :userId AND NOT EXISTS (SELECT 1 FROM propias)
                )
                SELECT %s FROM asignaturas_catalogo ac
                WHERE ac.carrera_id IN (SELECT carrera_id FROM propias UNION SELECT carrera_id FROM por_perfil)
                ORDER BY CASE WHEN ac.curso IS NULL THEN 1 ELSE 0 END, ac.curso,
                         CASE WHEN ac.semestre IS NULL THEN 1 ELSE 0 END, ac.semestre, ac.nombre
                """.formatted(COLUMNS);
        return jdbc.sql(sql).param("userId", userId).query(AcademicCatalogJdbcAdapter::map).list();
    }

    private static CatalogSubject map(ResultSet rs, int row) throws SQLException {
        BigDecimal credits = rs.getBigDecimal("creditos");
        return new CatalogSubject(rs.getObject("id", UUID.class), rs.getObject("carrera_id", UUID.class),
                rs.getString("nombre"), (Integer) rs.getObject("curso"), (Integer) rs.getObject("semestre"),
                rs.getString("caracter"), credits == null ? null : credits.doubleValue(),
                (Integer) rs.getObject("horas"), rs.getString("url_guia_docente"), rs.getString("codigo"));
    }
}
