package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.admin;

import com.synaptixfit.domain.model.admin.AuditAction;
import com.synaptixfit.domain.model.admin.AuditEntity;
import com.synaptixfit.domain.model.admin.AuditEntry;
import com.synaptixfit.domain.model.admin.AuditLogItem;
import com.synaptixfit.domain.model.admin.AuditQuery;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.admin.AdminAuditPort;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.json.JsonMapper;

/**
 * Implementa {@link AdminAuditPort} sobre {@code admin_auditoria} con JdbcClient (la columna
 * {@code detalle} es jsonb y se serializa con Jackson).
 */
@Repository
public class AdminAuditJdbcAdapter implements AdminAuditPort {

    private static final TypeReference<LinkedHashMap<String, Object>> DETAILS = new TypeReference<>() { };
    private static final String REDACTED = "{\"redacted\": true}";

    private final JdbcClient jdbc;
    private final JsonMapper json;

    public AdminAuditJdbcAdapter(JdbcClient jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    @Override
    public void record(AuditEntry entry) {
        jdbc.sql("""
                        INSERT INTO admin_auditoria (id, admin_id, accion, entidad, entidad_id, detalle, creado_en)
                        VALUES (:id, :adminId, :action, :entity, :entityId, CAST(:details AS jsonb), :createdAt)
                        """)
                .param("id", entry.id())
                .param("adminId", entry.adminId())
                .param("action", entry.action().code())
                .param("entity", entry.entity().code())
                .param("entityId", entry.entityId())
                .param("details", json.writeValueAsString(entry.details()))
                .param("createdAt", JdbcValues.param(entry.createdAt()))
                .update();
    }

    @Override
    public PageResult<AuditLogItem> search(AuditQuery query, PageRequest page) {
        StringBuilder where = new StringBuilder(" WHERE 1 = 1");
        Map<String, Object> params = new LinkedHashMap<>();
        if (query.adminId() != null) {
            where.append(" AND a.admin_id = :adminId");
            params.put("adminId", query.adminId());
        }
        if (query.action() == AuditAction.OTHER) {
            where.append(" AND a.accion NOT IN (:knownActions)");
            params.put("knownActions", Arrays.stream(AuditAction.values())
                    .filter(a -> a != AuditAction.OTHER).map(AuditAction::code).toList());
        } else if (query.action() != null) {
            where.append(" AND a.accion = :action");
            params.put("action", query.action().code());
        }
        if (query.entity() == AuditEntity.OTHER) {
            where.append(" AND a.entidad NOT IN (:knownEntities)");
            params.put("knownEntities", Arrays.stream(AuditEntity.values())
                    .filter(e -> e != AuditEntity.OTHER).map(AuditEntity::code).toList());
        } else if (query.entity() != null) {
            where.append(" AND a.entidad = :entity");
            params.put("entity", query.entity().code());
        }
        if (query.entityId() != null) {
            where.append(" AND a.entidad_id = :entityId");
            params.put("entityId", query.entityId());
        }
        if (query.from() != null) {
            where.append(" AND a.creado_en >= :from");
            params.put("from", JdbcValues.param(query.from()));
        }
        if (query.to() != null) {
            where.append(" AND a.creado_en < :to");
            params.put("to", JdbcValues.param(query.to()));
        }
        long total = jdbc.sql("SELECT count(*) FROM admin_auditoria a" + where)
                .params(params).query(Long.class).single();
        Map<String, Object> pageParams = new LinkedHashMap<>(params);
        pageParams.put("limit", page.size());
        pageParams.put("offset", page.offset());
        List<AuditLogItem> items = jdbc.sql("""
                        SELECT a.id, a.admin_id, a.accion, a.entidad, a.entidad_id, a.detalle::text AS detalle,
                               a.creado_en, u.nombre_completo AS admin_nombre, u.email AS admin_email
                          FROM admin_auditoria a
                          LEFT JOIN usuarios u ON u.id = a.admin_id
                        """ + where + " ORDER BY a.creado_en DESC, a.id LIMIT :limit OFFSET :offset")
                .params(pageParams)
                .query((rs, n) -> toItem(rs))
                .list();
        return new PageResult<>(items, page.page(), page.size(), total);
    }

    @Override
    public int redactDetailsForEntity(UUID entityId) {
        return jdbc.sql("UPDATE admin_auditoria SET detalle = CAST(:redacted AS jsonb) WHERE entidad_id = :entityId")
                .param("redacted", REDACTED)
                .param("entityId", entityId)
                .update();
    }

    private AuditLogItem toItem(ResultSet rs) throws SQLException {
        String details = rs.getString("detalle");
        AuditEntry entry = new AuditEntry(
                JdbcValues.uuid(rs, "id"),
                JdbcValues.uuid(rs, "admin_id"),
                AuditAction.fromCode(rs.getString("accion")),
                AuditEntity.fromCode(rs.getString("entidad")),
                JdbcValues.uuid(rs, "entidad_id"),
                details == null ? Map.of() : json.readValue(details, DETAILS),
                JdbcValues.instant(rs, "creado_en"));
        return new AuditLogItem(entry, rs.getString("admin_nombre"), rs.getString("admin_email"));
    }
}
