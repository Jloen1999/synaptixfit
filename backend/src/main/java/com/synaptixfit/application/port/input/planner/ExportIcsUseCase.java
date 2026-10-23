package com.synaptixfit.application.port.input.planner;

import java.time.Instant;
import java.util.UUID;

/** Exporta los bloques y entregas de un rango como calendario iCalendar (texto {@code text/calendar}). */
public interface ExportIcsUseCase {

    String exportIcs(UUID userId, Instant from, Instant to);
}
