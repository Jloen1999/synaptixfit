package com.synaptixfit.application.port.input.run;

import com.synaptixfit.domain.model.planner.ActivityKind;
import com.synaptixfit.domain.model.run.RunDetail;
import com.synaptixfit.domain.model.run.TrackPoint;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Guarda una carrera grabada con el GPS (ADR 0037): calcula sus cifras con la ruta, la apunta como actividad (racha,
 * XP, carga física, retos y semana) y, si salió de un evento con entreno de carrera, deja ese evento hecho. Con la
 * misma {@code clientKey} devuelve la carrera ya guardada sin duplicarla.
 */
public interface RecordRunUseCase {

    /**
     * @param kind           correr, andar o bici
     * @param effort         «¿Cuánto te ha costado?» (1-10)
     * @param workoutId      entreno de carrera con el que se grabó (opcional)
     * @param plannedBlockId evento del calendario que se estaba haciendo (opcional)
     */
    record Command(UUID userId, UUID clientKey, ActivityKind kind, Instant startedAt, int effort,
                   List<TrackPoint> points, UUID workoutId, UUID plannedBlockId) {
    }

    /**
     * La carrera guardada, la XP que sumó (0 si ya estaba guardada o si se pasó el tope del día) y si se ha guardado
     * ahora ({@code created}) o ya estaba (un reintento con la misma {@code clientKey}).
     */
    record Result(RunDetail run, int xpDelta, boolean created) {
    }

    Result recordRun(Command command);
}
