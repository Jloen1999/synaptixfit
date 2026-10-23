package com.synaptixfit.application.port.input.planner;

import java.util.UUID;

/**
 * Importa el calendario ICS de una asignatura (URL indicada o la configurada en la asignatura).
 * Exámenes y entregas crean entrega + bloque; el resto, bloques de clase. Todo inamovible e
 * idempotente por {@code ics_uid}. Si ningún evento menciona la asignatura no se importa nada salvo
 * que se fuerce.
 */
public interface ImportIcsUseCase {

    /** @param force importar todos los eventos aunque no mencionen la asignatura */
    record Command(UUID userId, UUID subjectId, String url, boolean force) {
    }

    /** Coincidencia de los eventos con la asignatura. */
    enum Match {
        FULL,
        PARTIAL,
        NONE
    }

    /**
     * @param imported   false si no se importó nada por falta de coincidencias
     * @param created    filas nuevas (bloques + entregas)
     * @param updated    filas existentes actualizadas
     */
    record Result(Match match, int totalEvents, int matchingEvents, int classes, int exams, int deliveries,
                  int created, int updated, boolean imported) {
    }

    Result importIcs(Command command);
}
