package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.application.port.input.training.RoutineStructureInput;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.PendingDay;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.ProgressStatus;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.TrackingKind;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.infrastructure.adapter.input.rest.support.LocalizedNames;
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
import java.util.Optional;
import java.util.UUID;

/** DTOs de rutinas. */
public final class RoutineDtos {

    private RoutineDtos() {
    }

    // ------------------------------------------------------------------ entrada

    /**
     * Parámetros de un ejercicio planificado (mismos rangos que el dominio). {@code repsPerSet},
     * {@code weightsKg} e {@code isometricSecondsPerSet} detallan cada serie (ADR 0027); sin ellos, todas
     * usan el valor común.
     */
    public record ExerciseParametersRequest(@NotNull @Min(1) @Max(10) Integer sets,
                                            @NotNull @Min(1) @Max(100) Integer reps,
                                            @NotNull @Min(30) @Max(300) Integer restSeconds,
                                            @DecimalMin("0") @DecimalMax("500") Double weightKg,
                                            @Size(max = 10) List<@NotNull @DecimalMin("0") @DecimalMax("500") Double> weightsKg,
                                            @Min(1) @Max(14400) Integer targetDurationSeconds,
                                            @Min(1) @Max(100000) Integer distanceMeters,
                                            @Min(1) @Max(600) Integer isometricSeconds,
                                            @Size(max = 10) List<@NotNull @Min(1) @Max(100) Integer> repsPerSet,
                                            @Size(max = 10) List<@NotNull @Min(1) @Max(600) Integer> isometricSecondsPerSet) {
        public ExerciseParameters toDomain() {
            return new ExerciseParameters(sets, reps, restSeconds, weightKg, weightsKg, targetDurationSeconds,
                    distanceMeters, isometricSeconds, repsPerSet, isometricSecondsPerSet);
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
                                         @Min(1) @Max(600) Integer isometricSeconds,
                                         @Size(max = 10) List<@NotNull @Min(1) @Max(100) Integer> repsPerSet,
                                         @Size(max = 10) List<@NotNull @Min(1) @Max(600) Integer> isometricSecondsPerSet) {
        public ExerciseParameters parameters() {
            return new ExerciseParameters(sets, reps, restSeconds, weightKg, weightsKg, targetDurationSeconds,
                    distanceMeters, isometricSeconds, repsPerSet, isometricSecondsPerSet);
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

    /** Ejercicio del catálogo que sustituye al de un hueco. */
    public record ReplaceExerciseRequest(@NotNull UUID exerciseId) {
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
                                          Integer isometricSeconds, Integer realDurationSeconds,
                                          List<Integer> repsPerSet, List<Integer> isometricSecondsPerSet,
                                          TrackingKind trackingKind) {
        public static PlannedExerciseResponse from(PlannedExercise p) {
            ExerciseParameters x = p.parameters();
            return new PlannedExerciseResponse(p.id(), p.exerciseId(),
                    LocalizedNames.exercise(p.exerciseId(), p.exercise().name()), p.exercise().gifUrl(),
                    p.exercise().previewUrl(), p.exercise().modality(), p.exercise().measurementTypes(),
                    p.exercise().effectiveMet(), p.exercise().active(), p.order(), x.sets(), x.reps(), x.restSeconds(),
                    x.weightKg(), x.weightsKg(), x.targetDurationSeconds(), x.distanceMeters(), x.isometricSeconds(),
                    p.realDurationSeconds(), x.repsPerSet(), x.isometricSecondsPerSet(), p.trackingKind());
        }
    }

    /**
     * Día de la rutina. {@code dayNumber} es el día de la semana preferido (1 = lunes); {@code name} es
     * nulo si no tiene nombre propio; {@code closedOn}, el día en que se completó o se saltó.
     */
    public record DayResponse(UUID id, int dayNumber, String name, ProgressStatus status, LocalDate closedOn,
                              List<PlannedExerciseResponse> exercises) {
        public static DayResponse from(RoutineDay d) {
            return new DayResponse(d.id(), d.number(), d.name(), d.status(), d.closedOn(),
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
                                  int completedDays, int skippedDays, OriginResponse origin, Instant createdAt,
                                  List<WeekResponse> weeks) {
        public static RoutineResponse from(Routine r, String authorName, java.util.UUID viewerId) {
            return new RoutineResponse(r.id(), r.ownerId(), authorName, r.isOwnedBy(viewerId), r.name(),
                    r.description(), r.visibility(), r.status(), r.goal(), r.startDate(), r.durationWeeks(),
                    r.exerciseCount(), r.totalDays(), r.completedDays(), r.skippedDays(), originOf(r), r.createdAt(),
                    r.weeks().stream().map(WeekResponse::from).toList());
        }
    }

    /**
     * Rutina sin estructura (listados). {@code coverImageUrl}/{@code coverModality}: foto y modalidad del
     * ejercicio que la representa (el primero del día que toca), para el fondo de su tarjeta.
     */
    public record RoutineSummaryResponse(UUID id, UUID ownerId, String authorName, String name, String description,
                                         Visibility visibility, RoutineStatus status, TrainingGoal goal,
                                         LocalDate startDate, int durationWeeks, int exerciseCount, int totalDays,
                                         int completedDays, OriginResponse origin, Instant createdAt,
                                         int skippedDays, String coverImageUrl, Modality coverModality) {
        public static RoutineSummaryResponse from(Routine r, String authorName) {
            Optional<ExerciseRef> cover = r.coverExercise();
            return new RoutineSummaryResponse(r.id(), r.ownerId(), authorName, r.name(), r.description(),
                    r.visibility(), r.status(), r.goal(), r.startDate(), r.durationWeeks(), r.exerciseCount(),
                    r.totalDays(), r.completedDays(), originOf(r), r.createdAt(), r.skippedDays(),
                    cover.map(ExerciseRef::stillImageUrl).orElse(null),
                    cover.map(ExerciseRef::modality).orElse(null));
        }
    }



    /**
     * Próximo día de entrenamiento (regla única {@code RoutineSchedule}). {@code dayStatus}: PENDING o
     * IN_PROGRESS (en curso de verdad, no abandonada); {@code scheduledDate}: cuándo toca;
     * {@code overdue}: esa fecha ya pasó; {@code sessionOfWeek}/{@code sessionsInWeek}: «sesión 2 de 3»;
     * {@code staleSessionId}: sesión abandonada de ese día que hay que terminar o descartar antes.
     */
    public record PendingDayResponse(UUID routineId, String routineName, UUID weekId, int weekNumber, int totalWeeks,
                                     String weekName, UUID dayId, int dayNumber, String dayName,
                                     ProgressStatus dayStatus, LocalDate scheduledDate, boolean overdue,
                                     int sessionOfWeek, int sessionsInWeek, UUID staleSessionId,
                                     List<PlannedExerciseResponse> exercises, int totalDays, int completedDays,
                                     int skippedDays, String coverImageUrl, Modality coverModality) {
        public static PendingDayResponse from(PendingDay p) {
            Routine r = p.routine();
            // La foto es la del día que se propone (puede no ser el primero pendiente si hay uno en curso).
            Optional<ExerciseRef> cover = p.day().coverExercise();
            return new PendingDayResponse(r.id(), r.name(), p.week().id(), p.week().number(),
                    r.durationWeeks(), p.week().name(), p.day().id(), p.day().number(), p.day().name(),
                    p.status(), p.scheduledDate(), p.overdue(), p.sessionOfWeek(), p.sessionsInWeek(),
                    p.staleSessionId(), p.day().exercises().stream().map(PlannedExerciseResponse::from).toList(),
                    r.totalDays(), r.completedDays(), r.skippedDays(),
                    cover.map(ExerciseRef::stillImageUrl).orElse(null),
                    cover.map(ExerciseRef::modality).orElse(null));
        }
    }

    private static OriginResponse originOf(Routine r) {
        return r.origin() == null ? null
                : new OriginResponse(r.origin().routineId(), r.origin().ownerId(), r.origin().ownerName());
    }
}
