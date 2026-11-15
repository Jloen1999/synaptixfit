package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.TrainingGoal;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** DTOs de los enlaces de rutina (ADR 0043): los del dueño y los de quien abre el enlace. */
public final class RoutineShareDtos {

    private RoutineShareDtos() {
    }

    /** Token del enlace nuevo (solo se ve ahora) y hasta cuándo vale. */
    public record ShareLinkResponse(String token, Instant expiresAt) {
    }

    /** Hasta cuándo vale el último enlace vigente; {@code null} si no se está compartiendo. */
    public record ShareLinkStatusResponse(Instant sharedUntil) {
    }

    /** Token del enlace tal como llega en la dirección. */
    public record SharedRoutineRequest(@NotBlank @Size(max = 128) String token) {
    }

    /** Ejercicio del resumen: nombre, foto y series de la primera semana. */
    public record SharedExerciseResponse(UUID exerciseId, String name, String imageUrl, int sets) {
    }

    /** Día de la primera semana con sus ejercicios. */
    public record SharedDayResponse(int dayNumber, String name, int estimatedMinutes,
                                    List<SharedExerciseResponse> exercises) {
    }

    /** Resumen de la rutina compartida: nombre, objetivo, semanas, días por semana y la primera semana. */
    public record SharedRoutineResponse(String name, String description, TrainingGoal goal, int durationWeeks,
                                        int daysPerWeek, int exerciseCount, List<SharedDayResponse> firstWeek) {
        public static SharedRoutineResponse from(Routine r) {
            List<RoutineDay> days = r.weeks().stream().findFirst().map(RoutineWeek::days).orElse(List.of());
            return new SharedRoutineResponse(r.name(), r.description(), r.goal(), r.durationWeeks(), days.size(),
                    r.exerciseCount(), days.stream().map(d -> new SharedDayResponse(d.number(), d.name(),
                            d.estimatedMinutes(), d.exercises().stream().map(SharedRoutineResponse::exercise)
                            .toList())).toList());
        }

        private static SharedExerciseResponse exercise(PlannedExercise e) {
            ExerciseRef ref = e.exercise();
            return new SharedExerciseResponse(ref.id(), ref.name(), ref.stillImageUrl(), e.parameters().sets());
        }
    }
}
