package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import com.synaptixfit.domain.model.admin.LockdownState;
import java.time.Instant;
import java.util.UUID;

/** Estado del modo bloqueo. {@code startedAt}/{@code startedBy} solo con el bloqueo activo. */
public record LockdownResponse(boolean active, Instant startedAt, UUID startedBy, Instant updatedAt) {

    public static LockdownResponse from(LockdownState s) {
        return new LockdownResponse(s.active(), s.startedAt(), s.startedBy(), s.updatedAt());
    }
}
