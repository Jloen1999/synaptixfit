package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.social;

import com.synaptixfit.domain.model.social.UserReport;
import com.synaptixfit.domain.port.output.social.UserReportRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.admin.JdbcValues;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/** Implementa {@link UserReportRepositoryPort} sobre {@code denuncias_usuario} (V1064, ADR 0044). */
@Component
public class UserReportJdbcAdapter implements UserReportRepositoryPort {

    private final JdbcClient jdbc;

    public UserReportJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void save(UserReport report) {
        jdbc.sql("INSERT INTO denuncias_usuario (id, denunciante_id, denunciado_id, contexto, creado_en)"
                        + " VALUES (:id, :reporter, :reported, :context, :created)")
                .param("id", report.id())
                .param("reporter", report.reporterId())
                .param("reported", report.reportedId())
                .param("context", report.context().name())
                .param("created", JdbcValues.param(report.createdAt()))
                .update();
    }

    @Override
    public boolean existsPending(UUID reporterId, UUID reportedId) {
        return jdbc.sql("SELECT count(*) FROM denuncias_usuario WHERE denunciante_id = :reporter"
                        + " AND denunciado_id = :reported")
                .param("reporter", reporterId)
                .param("reported", reportedId)
                .query(Long.class).single() > 0;
    }

    @Override
    public boolean delete(UUID id) {
        return jdbc.sql("DELETE FROM denuncias_usuario WHERE id = :id").param("id", id).update() > 0;
    }
}
