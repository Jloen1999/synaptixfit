package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.application.port.input.training.GetSessionAdaptationUseCase;
import com.synaptixfit.application.port.input.training.RecordSessionSetUseCase;
import com.synaptixfit.domain.model.training.OpenTrainingSession;
import com.synaptixfit.domain.model.training.SessionAdaptation;
import com.synaptixfit.domain.model.training.SessionLabel;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.SessionType;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.user.ExperienceChange;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** DTOs de sesiones de entrenamiento. */
public final class SessionDtos {

    private SessionDtos() {
    }

    /** Estado de una sesión. */
    public enum SessionStatus {
        IN_PROGRESS,
        COMPLETED
    }

    /** Ambos nulos: sesión libre. {@code dayId} exige {@code routineId}. */
    public record StartSessionRequest(UUID routineId, UUID dayId) {
    }

    /**
     * Serie realizada; {@code completed} por defecto true. Repetir {@code plannedExerciseId}+{@code setNumber}
     * la sustituye. {@code durationSeconds}/{@code distanceMeters}: en ejercicios de tiempo o distancia.
     */
    public record RecordSetRequest(UUID plannedExerciseId, @NotNull @Min(1) @Max(50) Integer setNumber,
                                   @Min(0) @Max(1000) Integer repsDone,
                                   @DecimalMin("0") @DecimalMax("500") Double weightKg,
                                   Boolean completed, @Min(0) @Max(1000) Integer failedReps,
                                   @Min(0) @Max(14400) Integer durationSeconds,
                                   @Min(0) @Max(100000) Integer distanceMeters) {
        public RecordSessionSetUseCase.Command toCommand(UUID userId, UUID sessionId) {
            return new RecordSessionSetUseCase.Command(userId, sessionId, plannedExerciseId, setNumber, repsDone,
                    weightKg, completed == null || completed, failedReps == null ? 0 : failedReps, durationSeconds,
                    distanceMeters);
        }
    }

    /**
     * Finalizar: duración total en segundos, RPE 1-10, duración real por ejercicio planificado
     * ({@code plannedExerciseId → segundos}) y, opcionalmente, las series que falten por registrar.
     */
    public record FinishSessionRequest(@NotNull @Min(1) @Max(86400) Long durationSeconds,
                                       @NotNull @Min(1) @Max(10) Integer rpe,
                                       Map<UUID, @NotNull @Min(1) @Max(14400) Integer> realDurations,
                                       @Size(max = 300) List<@Valid @NotNull RecordSetRequest> sets) {
    }

    /** Corregir una sesión terminada: RPE 1-10 y duración en minutos (1-240). */
    public record CorrectSessionRequest(@NotNull @Min(1) @Max(10) Integer rpe,
                                        @NotNull @Min(1) @Max(240) Integer durationMinutes) {
    }

    /** Registrar un día de rutina hecho sin la app: fecha de hoy o de los 7 días anteriores. */
    public record PastSessionRequest(@NotNull UUID routineId, @NotNull UUID dayId, @NotNull LocalDate date,
                                     @NotNull @Min(1) @Max(240) Integer durationMinutes,
                                     @NotNull @Min(1) @Max(10) Integer rpe) {
    }

    /**
     * Sesión sin terminar con su nombre. {@code stale}: abandonada (más de 6 h abierta): se termina con
     * lo registrado o se descarta. Rutina y día nulos en sesiones libres; {@code dayName} nulo si el día
     * no tiene nombre propio.
     */
    public record OpenSessionResponse(SessionResponse session, boolean stale, String routineName, String dayName,
                                      Integer dayNumber, Integer weekNumber) {
        public static OpenSessionResponse from(OpenTrainingSession o) {
            SessionLabel l = o.label();
            return new OpenSessionResponse(SessionResponse.from(o.session()), o.stale(),
                    l == null ? null : l.routineName(), l == null ? null : l.dayName(),
                    l == null ? null : l.dayNumber(), l == null ? null : l.weekNumber());
        }
    }

    public record PastSessionResponse(SessionResponse session, ExperienceResponse experience) {
    }

    public record SessionSetResponse(UUID id, UUID plannedExerciseId, int setNumber, Integer repsDone, Double weightKg,
                                     boolean completed, int failedReps, Integer durationSeconds,
                                     Integer distanceMeters, UUID exerciseId) {
        static SessionSetResponse from(SessionSet s) {
            return new SessionSetResponse(s.id(), s.plannedExerciseId(), s.setNumber(), s.repsDone(), s.weightKg(),
                    s.completed(), s.failedReps(), s.durationSeconds(), s.distanceMeters(), s.exerciseId());
        }
    }

    /** Adaptación de hoy: factor de volumen, motivos y series por ejercicio planificado. */
    public record SessionAdaptationResponse(double volumeFactor, List<SessionAdaptation.Reason> reasons,
                                            Map<UUID, Integer> sets) {

        public static SessionAdaptationResponse from(GetSessionAdaptationUseCase.Result r) {
            return new SessionAdaptationResponse(r.adaptation().volumeFactor(), r.adaptation().reasons(), r.sets());
        }
    }

    public record SessionResponse(UUID id, UUID routineId, UUID dayId, SessionType type, SessionStatus status,
                                  Instant startedAt, Instant completedAt, int durationMinutes, Integer rpe,
                                  Double calories, int xpAwarded, List<SessionSetResponse> sets) {
        public static SessionResponse from(TrainingSession s) {
            return new SessionResponse(s.id(), s.routineId(), s.dayId(), s.type(),
                    s.isCompleted() ? SessionStatus.COMPLETED : SessionStatus.IN_PROGRESS, s.startedAt(),
                    s.completedAt(), s.durationMinutes(), s.rpe(), s.calories(), s.xpAwarded(),
                    s.sets().stream().map(SessionSetResponse::from).toList());
        }
    }

    /** Cambio de experiencia: nivel y experiencia dentro del nivel tras el cambio, niveles subidos/bajados y delta. */
    public record ExperienceResponse(int level, int levelXp, int levelUps, int xpDelta) {
        public static ExperienceResponse from(ExperienceChange c) {
            return new ExperienceResponse(c.level(), c.levelXp(), c.levelUps(), c.xpDelta());
        }
    }

    public record FinishSessionResponse(SessionResponse session, ExperienceResponse experience,
                                        List<RecommendationDtos.RecommendationResponse> recommendations) {
    }

    public record UnmarkSessionResponse(SessionResponse session, ExperienceResponse experience) {
    }
}
