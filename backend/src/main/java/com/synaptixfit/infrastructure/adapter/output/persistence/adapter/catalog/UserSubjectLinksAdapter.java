package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.catalog;

import com.synaptixfit.domain.model.catalog.SubjectLink;
import com.synaptixfit.domain.port.output.catalog.UserSubjectLinksPort;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/** Lee {@code asignaturas} (módulo académico) con {@link JdbcClient}; nunca escribe. */
@Repository
public class UserSubjectLinksAdapter implements UserSubjectLinksPort {

    private final JdbcClient jdbc;

    public UserSubjectLinksAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Map<UUID, SubjectLink> findByCatalogSubjects(UUID userId, Collection<UUID> catalogSubjectIds) {
        Map<UUID, SubjectLink> result = new HashMap<>();
        if (catalogSubjectIds.isEmpty()) {
            return result;
        }
        jdbc.sql("""
                        SELECT id, catalogo_asignatura_id, archivado FROM asignaturas
                        WHERE usuario_id = :userId AND catalogo_asignatura_id IN (:ids)
                        """)
                .param("userId", userId)
                .param("ids", catalogSubjectIds)
                .query((rs, n) -> Map.entry(rs.getObject("catalogo_asignatura_id", UUID.class),
                        new SubjectLink(rs.getObject("id", UUID.class), rs.getBoolean("archivado"))))
                .list()
                // Si hay duplicados se prefiere la asignatura activa.
                .forEach(e -> result.merge(e.getKey(), e.getValue(), (a, b) -> a.archived() ? b : a));
        return result;
    }
}
