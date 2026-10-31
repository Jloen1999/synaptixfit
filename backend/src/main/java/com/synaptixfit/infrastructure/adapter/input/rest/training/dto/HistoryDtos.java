package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.domain.model.training.PersonalRecord;
import com.synaptixfit.domain.model.training.SessionHighlights;
import com.synaptixfit.domain.model.training.SessionHistoryEntry;
import com.synaptixfit.domain.model.training.SessionLabel;
import com.synaptixfit.infrastructure.adapter.input.rest.support.LocalizedNames;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.SessionResponse;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** DTOs del historial de entrenamiento y de los récords personales. */
public final class HistoryDtos {

    private HistoryDtos() {
    }

    /** Resumen destacado de una sesión terminada. */
    public record SessionHighlightsResponse(UUID sessionId, double volumeKg, int totalReps, int completedSets,
                                            List<PersonalRecordResponse> records, Double previousVolumeKg,
                                            Integer previousDurationMinutes) {
        public static SessionHighlightsResponse from(SessionHighlights h) {
            return new SessionHighlightsResponse(h.sessionId(), h.volumeKg(), h.totalReps(), h.completedSets(),
                    h.records().stream().map(PersonalRecordResponse::from).toList(), h.previousVolumeKg(),
                    h.previousDurationMinutes());
        }
    }

    /** Récord: con {@code kind = WEIGHT} manda {@code weightKg}; con {@code REPS}, las repeticiones. */
    public record PersonalRecordResponse(UUID exerciseId, String exerciseName, PersonalRecord.Kind kind,
                                         Double weightKg, int reps, UUID sessionId, Instant achievedAt) {
        public static PersonalRecordResponse from(PersonalRecord r) {
            return new PersonalRecordResponse(r.exerciseId(), LocalizedNames.exercise(r.exerciseId(), r.exerciseName()), r.kind(), r.weightKg(), r.reps(),
                    r.sessionId(), r.achievedAt());
        }
    }

    /**
     * Sesión del historial. {@code dayName} es nulo si el día no tiene nombre (el cliente muestra
     * «Día N» con {@code dayNumber}); rutina, día y semana son nulos en sesiones libres.
     */
    public record SessionHistoryResponse(SessionResponse session, String routineName, String dayName,
                                         Integer dayNumber, Integer weekNumber,
                                         List<PersonalRecordResponse> records) {
        public static SessionHistoryResponse from(SessionHistoryEntry e) {
            SessionLabel label = e.label();
            return new SessionHistoryResponse(SessionResponse.from(e.session()),
                    label == null ? null : label.routineName(), label == null ? null : label.dayName(),
                    label == null ? null : label.dayNumber(), label == null ? null : label.weekNumber(),
                    e.records().stream().map(PersonalRecordResponse::from).toList());
        }
    }
}
