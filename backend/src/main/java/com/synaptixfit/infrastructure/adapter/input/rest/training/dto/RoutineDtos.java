package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.application.port.input.training.RoutineStructureInput;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.PendingDay;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.ProgressStatus;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.WeekType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** DTOs de rutinas. */
public final class RoutineDtos {

    private RoutineDtos() {
    }

    // ------------------------------------------------------------------ entrada

    /** Parámetros de un ejercicio planificado (mismos rangos que el dominio). */
    public record ExerciseParametersRequest(@NotNull @Min(1) @Max(10) Integer sets,
                                            @NotNull @Min(1) @Max(100) Integer reps,
                                            @NotNull @Min(30) @Max(300) Integer restSeconds,
                                            @DecimalMin("0") @DecimalMax("500") Double weightKg,
                                            @Size(max = 10) List<@NotNull @DecimalMin("0") @DecimalMax("500") Double> weightsKg,
                                            @Min(1) @Max(14400) Integer targetDurationSeconds,
                                            @Min(1) @Max(100000) Integer distanceMeters,
                                            @Min(1) @Max(600) Integer isometricSeconds) {
        public ExerciseParameters toDomain() {
            return new ExerciseParameters(sets, reps, restSeconds, weightKg, weightsKg, targetDurationSeconds,
                    distanceMeters, isometricSeconds);
        }
    }

    /** Ejercicio del catálogo con sus parámetros. */
    public record PlannedExerciseRequest(@NotNull UUID exerciseId,
                                         @NotNull @Min(1) @Max(10) Integer sets,
                                         @NotNull @Min(1) @Max(100) Integer reps,
                                         @NotNull @Min(30) @Max(300) Integer restSeconds,
                                         @DecimalMin("0") @DecimalMax("500") Double weightKg,
                                         @Size(max = 10) List<@NotNull @DecimalMin("0") @DecimalMax("500") Double> weightsKg,
                                         @Min(1) @Max(14400) Integer targetDurationSeconds,
                                         @Min(1) @Max(100000) Integer distanceMeters,
                                         @Min(1) @Max(600) Integer isometricSeconds) {
        public ExerciseParameters parameters() {
            return new ExerciseParameters(sets, reps, restSeconds, weightKg, weightsKg, targetDurationSeconds,
                    distanceMeters, isometricSeconds);
        }
    }

    /** Día (1-7) de una semana nueva. */
    public record DayRequest(@NotNull @Min(1) @Max(7) Integer dayNumber, @Size(max = 120) String name,
                             @Size(max = 30) List<@Valid @NotNull PlannedExerciseRequest> exercises) {
    }

    /** Semana nueva; {@code type} nulo usa el tipo por posición. */
    public record WeekRequest(@Size(max = 120) String name, WeekType type,
                              @Size(max = 7) List<@Valid @NotNull DayRequest> days) {
    }

    /** Alta completa de una rutina (también acepta tal cual una propuesta generada). */
    public record CreateRoutineRequest(@NotBlank @Size(min = 3, max = 120) String name,
                                       @Size(max = 2000) String description,
                                       Visibility visibility,
                                       TrainingGoal goal,
                                       LocalDate startDate,
                                       @NotEmpty @Size(max = 52) List<@Valid @NotNull WeekRequest> weeks) {
        public List<RoutineStructureInput.Week> structure() {
            return weeks.stream().map(w -> new RoutineStructureInput.Week(w.name(), w.type(),
                    (w.days() == null ? List.<DayRequest>of() : w.days()).stream()
                            .map(d -> new RoutineStructureInput.Day(d.dayNumber(), d.name(),
                                    (d.exercises() == null ? List.<PlannedExerciseRequest>of() : d.exercises()).stream()
                                            .map(e -> new RoutineStructureInput.Exercise(e.exerciseId(), e.parameters()))
                                            .toList()))
                            .toList()))
                    .toList();
        }
    }

    /** Edición parcial: los campos nulos no cambian; {@code clearStartDate} borra la fecha de inicio. */
    public record UpdateRoutineRequest(@Size(min = 3, max = 120) String name, @Size(max = 2000) String description,
                                       Visibility visibility, TrainingGoal goal, LocalDate startDate,
                                       Boolean clearStartDate) {
    }

    public record ChangeRoutineStatusRequest(@NotNull RoutineStatus status) {
    }

    public record DuplicateRoutineRequest(@Size(min = 3, max = 120) String name) {
    }

    public record WeekChangeRequest(@Size(max = 120) String name, WeekType type) {
    }

    public record AddDayRequest(@NotNull @Min(1) @Max(7) Integer dayNumber, @Size(max = 120) String name) {
    }

    public record RenameDayRequest(@NotBlank @Size(max = 120) String name) {
    }

    public record ReorderExercisesRequest(@NotEmpty List<@NotNull UUID> plannedExerciseIds) {
    }

    // ------------------------------------------------------------------ salida

    public record OriginResponse(UUID routineId, UUID ownerId, String ownerName) {
    }

    /** Ejercicio planificado con los datos del ejercicio. */
    public record PlannedExerciseResponse(UUID id, UUID exerciseId, String exerciseName, String gifUrl,
                                          String previewUrl, Modality modality, List<MeasurementType> measurementTypes,
                                          double met, boolean exerciseActive, int order, int sets, int reps,
                                          int restSeconds, Double weightKg, List<Double> weightsKg,
                                          Integer targetDurationSeconds, Integer distanceMeters,
                                          Integer isometricSeconds, Integer realDurationSeconds) {
        public static PlannedExerciseResponse from(PlannedExercise p) {
            ExerciseParameters x = p.parameters();
            return new PlannedExerciseResponse(p.id(), p.exerciseId(), p.exercise().name(), p.exercise().gifUrl(),
                    p.exercise().previewUrl(), p.exercise().modality(), p.exercise().measurementTypes(),
                    p.exercise().effectiveMet(), p.exercise().active(), p.order(), x.sets(), x.reps(), x.restSeconds(),
                    x.weightKg(), x.weightsKg(), x.targetDurationSeconds(), x.distanceMeters(), x.isometricSeconds(),
                    p.realDurationSeconds());
        }
    }

    public record DayResponse(UUID id, int dayNumber, String name, ProgressStatus status,
                              List<PlannedExerciseResponse> exercises) {
        public static DayResponse from(RoutineDay d) {
            return new DayResponse(d.id(), d.number(), d.name(), d.status(),
                    d.exercises().stream().map(PlannedExerciseResponse::from).toList());
        }
    }

    public record WeekResponse(UUID id, int number, String name, WeekType type, ProgressStatus status,
                               List<DayResponse> days) {
        public static WeekResponse from(RoutineWeek w) {
            return new WeekResponse(w.id(), w.number(), w.name(), w.type(), w.status(),
                    w.days().stream().map(DayResponse::from).toList());
        }
    }

    /** Rutina completa. {@code owned} indica si es del usuario (si no, es de la comunidad y solo se puede clonar). */
    public record RoutineResponse(UUID id, UUID ownerId, String authorName, boolean owned, String name,
                                  String description, Visibility visibility, RoutineStatus status, TrainingGoal goal,
                                  LocalDate startDate, int durationWeeks, int exerciseCount, int totalDays,
                                  int completedDays, OriginResponse origin, Instant createdAt,
                                  List<WeekResponse> weeks) {
        public static RoutineResponse from(Routine r, String authorName, java.util.UUID viewerId) {
            return new RoutineResponse(r.id(), r.ownerId(), authorName, r.isOwnedBy(viewerId), r.name(),
                    r.description(), r.visibility(), r.status(), r.goal(), r.startDate(), r.durationWeeks(),
                    r.exerciseCount(), r.totalDays(), r.completedDays(), originOf(r), r.createdAt(),
                    r.weeks().stream().map(WeekResponse::from).toList());
        }
    }

    /** Rutina sin estructura (listados). */
    public record RoutineSummaryResponse(UUID id, UUID ownerId, String authorName, String name, String description,
                                         Visibility visibility, RoutineStatus status, TrainingGoal goal,
                                         LocalDate startDate, int durationWeeks, int exerciseCount, int totalDays,
                                         int completedDays, OriginResponse origin, Instant createdAt) {
        public static RoutineSummaryResponse from(Routine r, String authorName) {
            return new RoutineSummaryResponse(r.id(), r.ownerId(), authorName, r.name(), r.description(),
                    r.visibility(), r.status(), r.goal(), r.startDate(), r.durationWeeks(), r.exerciseCount(),
                    r.totalDays(), r.completedDays(), originOf(r), r.createdAt());
        }
    }

    /** Próximo día de entrenamiento pendiente. */
    public record PendingDayResponse(UUID routineId, String routineName, UUID weekId, int weekNumber, String weekName,
                                     UUID dayId, int dayNumber, String dayName, ProgressStatus dayStatus,
                                     List<PlannedExerciseResponse> exercises) {
        public static PendingDayResponse from(PendingDay p) {
            return new PendingDayResponse(p.routine().id(), p.routine().name(), p.week().id(), p.week().number(),
                    p.week().name(), p.day().id(), p.day().number(), p.day().name(), p.day().status(),
                    p.day().exercises().stream().map(PlannedExerciseResponse::from).toList());
        }
    }

    private static OriginResponse originOf(Routine r) {
        return r.origin() == null ? null
                : new OriginResponse(r.origin().routineId(), r.origin().ownerId(), r.origin().ownerName());
    }
}
