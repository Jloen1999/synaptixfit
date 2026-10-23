package com.synaptixfit.domain.model.notification;

/** Notificaciones no leídas por prioridad. */
public record UnreadCounts(long critical, long recommended, long informative) {

    public long total() {
        return critical + recommended + informative;
    }
}
