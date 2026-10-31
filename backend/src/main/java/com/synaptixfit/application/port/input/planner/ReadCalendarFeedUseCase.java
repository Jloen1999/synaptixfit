package com.synaptixfit.application.port.input.planner;

/**
 * Calendario iCalendar de quien tiene el enlace (sin sesión: lo piden Google, Apple u Outlook): bloques y
 * entregas de los últimos 30 días y los próximos 180. Lanza CalendarFeedNotFoundException si el token no vale.
 */
public interface ReadCalendarFeedUseCase {

    String readFeed(String token);
}
