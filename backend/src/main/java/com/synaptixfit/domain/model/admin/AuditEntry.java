package com.synaptixfit.domain.model.admin;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * Registro inmutable de una acción administrativa.
 *
 * <p>{@code adminId} es nulo cuando la acción no la hace un administrador (baja voluntaria) o
 * cuando el administrador ya no existe. {@code details} guarda el antes/después de la operación.
 */
public record AuditEntry(UUID id, UUID adminId, AuditAction action, AuditEntity entity, UUID entityId,
                         Map<String, Object> details, Instant createdAt) {

    public AuditEntry {
        Objects.requireNonNull(id, "id");
        Guard.notNull(action, "action");
        Guard.notNull(entity, "entity");
        Objects.requireNonNull(createdAt, "createdAt");
        details = details == null ? Map.of() : Collections.unmodifiableMap(new LinkedHashMap<>(details));
    }

    /** Crea una entrada nueva. */
    public static AuditEntry of(UUID adminId, AuditAction action, AuditEntity entity, UUID entityId,
                                Map<String, Object> details, Instant now) {
        return new AuditEntry(UUID.randomUUID(), adminId, action, entity, entityId, details, now);
    }

    /** Detalle estándar con el valor anterior y el nuevo de un campo. */
    public static Map<String, Object> change(String field, Object before, Object after) {
        Map<String, Object> beforeMap = new LinkedHashMap<>();
        beforeMap.put(field, before);
        Map<String, Object> afterMap = new LinkedHashMap<>();
        afterMap.put(field, after);
        Map<String, Object> details = new LinkedHashMap<>();
        details.put("before", beforeMap);
        details.put("after", afterMap);
        return details;
    }
}
