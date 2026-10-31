package com.synaptixfit.application.port.input.planner;

import java.util.UUID;

/**
 * Importa un calendario general como el del Campus Virtual (Moodle): solo exámenes y entregas, cada uno en la
 * asignatura que mencione (o sin asignatura), sin clases ni avisos de apertura. Idempotente por {@code ics_uid}.
 * El resultado usa el mismo formato que {@link ImportIcsUseCase}; {@code matchingEvents} son los que tienen
 * asignatura.
 */
public interface ImportGeneralCalendarUseCase {

    record Command(UUID userId, String url) {
    }

    ImportIcsUseCase.Result importGeneral(Command command);
}
