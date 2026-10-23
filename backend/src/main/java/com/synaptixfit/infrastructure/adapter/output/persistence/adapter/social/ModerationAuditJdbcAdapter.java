package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.social;

import com.synaptixfit.domain.port.output.social.ModerationAuditPort;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

/**
 * Escribe en {@code admin_auditoria} (tabla del módulo de administración) solo como registro de
 * auditoría de la moderación social, por eso con JDBC y sin entidad propia. El id y la fecha los pone
 * la aplicación (no los valores por defecto de PostgreSQL), para no depender del motor.
 */
@Repository
public class ModerationAuditJdbcAdapter implements ModerationAuditPort {

    private final JdbcClient jdbc;
    private final JsonMapper json;
    private final Clock clock;

    public ModerationAuditJdbcAdapter(JdbcClient jdbc, JsonMapper json, Clock clock) {
        this.jdbc = jdbc;
        this.json = json;
        this.clock = clock;
    }

    @Override
    public void record(UUID adminId, String action, String entity, UUID entityId, Map<String, String> detail) {
        jdbc.sql("""
                        INSERT INTO admin_auditoria (id, admin_id, accion, entidad, entidad_id, detalle, creado_en)
                        VALUES (:id, :admin, :action, :entity, :entityId, CAST(:detail AS jsonb), :createdAt)
                        """)
                .param("id", UUID.randomUUID())
                .param("admin", adminId)
                .param("action", action)
                .param("entity", entity)
                .param("entityId", entityId)
                .param("detail", json.writeValueAsString(detail == null ? Map.of() : detail))
                .param("createdAt", OffsetDateTime.ofInstant(clock.instant(), ZoneOffset.UTC))
                .update();
    }
}
