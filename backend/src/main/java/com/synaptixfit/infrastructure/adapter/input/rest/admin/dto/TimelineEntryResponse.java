package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import com.synaptixfit.domain.model.admin.TimelineEntry;
import java.time.Instant;
import java.util.UUID;

/** Evento de la línea de tiempo de un usuario. */
public record TimelineEntryResponse(Instant occurredAt, TimelineEntry.Type type, UUID referenceId, String title,
                                    Integer value) {

    public static TimelineEntryResponse from(TimelineEntry e) {
        return new TimelineEntryResponse(e.occurredAt(), e.type(), e.referenceId(), e.title(), e.value());
    }
}
