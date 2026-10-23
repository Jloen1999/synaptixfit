package com.synaptixfit.infrastructure.adapter.input.rest.notification.dto;

import com.synaptixfit.domain.model.notification.UnreadCounts;

/** Notificaciones no leídas, en total y por prioridad. */
public record UnreadCountResponse(long total, long critical, long recommended, long informative) {

    public static UnreadCountResponse from(UnreadCounts c) {
        return new UnreadCountResponse(c.total(), c.critical(), c.recommended(), c.informative());
    }
}
