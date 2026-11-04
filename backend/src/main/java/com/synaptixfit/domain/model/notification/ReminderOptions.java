package com.synaptixfit.domain.model.notification;

/**
 * Avisos opcionales del móvil que se pueden apagar uno a uno, además de las categorías: racha en riesgo, registro
 * diario y clase a punto de empezar. Todos activos por defecto.
 */
public record ReminderOptions(boolean streak, boolean checkIn, boolean classes) {

    public static final ReminderOptions DEFAULTS = new ReminderOptions(true, true, true);
}
