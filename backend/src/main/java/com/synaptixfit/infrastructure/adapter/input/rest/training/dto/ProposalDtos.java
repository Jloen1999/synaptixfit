package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.model.training.generation.RoutineProposal;
import com.synaptixfit.infrastructure.adapter.input.rest.support.LocalizedNames;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/**
 * DTOs de la generación de rutinas. La propuesta tiene la misma forma que el alta
 * ({@code weeks[].days[].exercises[]}), así que se puede enviar tal cual a {@code POST /api/v1/routines}.
 */
public final class ProposalDtos {

    private ProposalDtos() {
    }

    /** Petición de generación: {@code goal} nulo usa el del perfil; {@code useAi} por defecto true. */
    public record GenerateRoutineRequest(@NotNull @Min(1) @Max(12) Integer durationWeeks, TrainingGoal goal,
                                         Boolean useAi) {
    }

    public record ProposedExerciseDto(@NotNull UUID exerciseId, String exerciseName,
                                      @NotNull @Min(1) @Max(10) Integer sets,
                                      @NotNull @Min(1) @Max(100) Integer reps,
                                      @NotNull @Min(30) @Max(300) Integer restSeconds,
                                      @DecimalMin("0") @DecimalMax("500") Double weightKg,
                                      @Size(max = 10) List<@NotNull Double> weightsKg,
                                      @Min(1) @Max(14400) Integer targetDurationSeconds,
                                      @Min(1) @Max(100000) Integer distanceMeters,
                                      @Min(1) @Max(600) Integer isometricSeconds) {
        static ProposedExerciseDto from(RoutineProposal.ProposedExercise e) {
            ExerciseParameters p = e.parameters();
            return new ProposedExerciseDto(e.exerciseId(), LocalizedNames.exercise(e.exerciseId(), e.exerciseName()), p.sets(), p.reps(), p.restSeconds(),
                    p.weightKg(), p.weightsKg(), p.targetDurationSeconds(), p.distanceMeters(), p.isometricSeconds());
        }

        RoutineProposal.ProposedExercise toDomain() {
            return new RoutineProposal.ProposedExercise(exerciseId, exerciseName, new ExerciseParameters(sets, reps,
                    restSeconds, weightKg, weightsKg, targetDurationSeconds, distanceMeters, isometricSeconds));
        }
    }

    public record ProposedDayDto(@NotNull @Min(1) @Max(7) Integer dayNumber, @Size(max = 120) String name,
                                 @Size(max = 30) List<@Valid @NotNull ProposedExerciseDto> exercises) {
        static ProposedDayDto from(RoutineProposal.ProposedDay d) {
            return new ProposedDayDto(d.dayNumber(), d.name(), d.exercises().stream().map(ProposedExerciseDto::from).toList());
        }

        RoutineProposal.ProposedDay toDomain() {
            return new RoutineProposal.ProposedDay(dayNumber, name,
                    (exercises == null ? List.<ProposedExerciseDto>of() : exercises).stream()
                            .map(ProposedExerciseDto::toDomain).toList());
        }
    }

    public record ProposedWeekDto(Integer number, @Size(max = 120) String name, WeekType type,
                                  @Size(max = 7) List<@Valid @NotNull ProposedDayDto> days) {
        static ProposedWeekDto from(RoutineProposal.ProposedWeek w) {
            return new ProposedWeekDto(w.number(), w.name(), w.type(), w.days().stream().map(ProposedDayDto::from).toList());
        }
    }

    /**
     * Propuesta de rutina (respuesta de generar/refinar y cuerpo de refinar). {@code aiRefined} indica
     * si la refinó la IA; {@code aiNotice} explica por qué no (IA no disponible).
     */
    public record RoutineProposalDto(@Size(min = 3, max = 120) String name, @Size(max = 2000) String description,
                                     @NotNull TrainingGoal goal, Integer durationWeeks, String split,
                                     List<String> adjustmentReasons, Double totalLoadFactor, Boolean aiRefined,
                                     String aiNotice, @NotEmpty @Size(max = 12) List<@Valid @NotNull ProposedWeekDto> weeks) {
        public static RoutineProposalDto from(RoutineProposal p) {
            return new RoutineProposalDto(p.name(), p.description(), p.goal(), p.durationWeeks(), p.split(),
                    p.adjustmentReasons(), p.totalLoadFactor(), p.aiRefined(), p.aiNotice(),
                    p.weeks().stream().map(ProposedWeekDto::from).toList());
        }

        public RoutineProposal toDomain() {
            List<RoutineProposal.ProposedWeek> list = new java.util.ArrayList<>();
            for (int i = 0; i < weeks.size(); i++) {
                ProposedWeekDto w = weeks.get(i);
                int number = i + 1;
                list.add(new RoutineProposal.ProposedWeek(number, w.name(),
                        w.type() == null ? WeekType.forPosition(number, weeks.size()) : w.type(),
                        (w.days() == null ? List.<ProposedDayDto>of() : w.days()).stream()
                                .map(ProposedDayDto::toDomain).toList()));
            }
            return new RoutineProposal(name, description, goal, list, split, adjustmentReasons,
                    totalLoadFactor == null ? 0 : totalLoadFactor, false, null);
        }
    }
}
