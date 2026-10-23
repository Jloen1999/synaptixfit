package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.profile;

import com.synaptixfit.domain.port.output.profile.UserSubjectsQueryPort;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/** Lee {@code asignaturas} (módulo académico) con {@link JdbcClient}; nunca escribe. */
@Repository
public class UserSubjectsQueryAdapter implements UserSubjectsQueryPort {

    private final JdbcClient jdbc;

    public UserSubjectsQueryAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public boolean hasActiveSubjects(UUID userId) {
        return Boolean.TRUE.equals(jdbc.sql("""
                        SELECT EXISTS (SELECT 1 FROM asignaturas WHERE usuario_id = :userId AND archivado = false)
                        """)
                .param("userId", userId)
                .query(Boolean.class)
                .single());
    }
}
