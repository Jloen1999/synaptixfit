package com.synaptixfit.domain.model.run;

import com.synaptixfit.domain.model.planner.ActivityKind;
import java.time.Instant;
import java.util.UUID;

/**
 * Carrera grabada con el GPS (ADR 0037). Es una actividad: vive en el bloque {@code blockId} del calendario, ya
 * completado, y aquí se guardan la ruta filtrada y las cifras que calculó el servidor.
 *
 * @param clientKey clave que genera el móvil al empezar a grabar: hace idempotente la subida desde la cola
 * @param workoutId entreno de carrera con el que se grabó (opcional)
 */
public record RecordedRun(UUID blockId, UUID userId, UUID clientKey, ActivityKind kind, Instant startedAt,
                          Instant endedAt, RunMetrics metrics, Integer kcal, int effort, UUID workoutId,
                          Instant createdAt) {
}
