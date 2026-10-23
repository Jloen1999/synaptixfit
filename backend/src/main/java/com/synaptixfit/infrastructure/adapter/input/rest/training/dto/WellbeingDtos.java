package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.application.port.input.training.WeeklyPlanProgress;
import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.model.training.PlanIntensity;
import com.synaptixfit.domain.model.training.PlanStatus;
import com.synaptixfit.domain.model.training.WeeklyTrainingPlan;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** DTOs del check-in diario y del plan semanal de entrenamiento. */
public final class WellbeingDtos {

    private WellbeingDtos() {
    }

    /** Check-in del día (escalas 1-5). {@code readyToTrain} por defecto true. */
    public record CheckInRequest(@NotNull @Min(1) @Max(5) Integer sleepQuality,
                                 @NotNull @Min(1) @Max(5) Integer stress,
                                 @NotNull @Min(1) @Max(5) Integer energy,
                                 @NotNull @Min(1) @Max(5) Integer soreness,
                                 @Size(max = 12) List<@NotBlank @Size(max = 40) String> painZones,
                                 Boolean readyToTrain,
                                 @Size(max = 1000) String notes) {
        public DailyCheckIn.Values toValues() {
            return new DailyCheckIn.Values(sleepQuality, stress, energy, soreness, painZones,
                    readyToTrain == null || readyToTrain, notes);
        }
    }

    /** Check-in con su puntuación de fatiga (0-100) y si conviene adaptar el entrenamiento (&gt; 50). */
    public record CheckInResponse(UUID id, LocalDate date, int sleepQuality, int stress, int energy, int soreness,
                                  List<String> painZones, boolean readyToTrain, String notes, int fatigueScore,
                                  boolean requiresAdaptation, Instant createdAt) {
        public static CheckInResponse from(DailyCheckIn c) {
            return new CheckInResponse(c.id(), c.date(), c.sleepQuality(), c.stress(), c.energy(), c.soreness(),
                    c.painZones(), c.readyToTrain(), c.notes(), c.fatigueScore(), c.requiresAdaptation(), c.createdAt());
        }
    }

    /** Resultado de guardar el check-in: {@code firstOfDay} si era el primero (da {@code xpAwarded}). */
    public record SubmitCheckInResponse(CheckInResponse checkIn, boolean firstOfDay, int xpAwarded) {
    }

    /** Plan semanal; {@code intensity} y {@code status} por defecto MODERATE y ACTIVE. */
    public record WeeklyPlanRequest(@NotNull @Min(1) @Max(7) Integer plannedSessions, PlanIntensity intensity,
                                    @NotNull @Min(10) @Max(180) Integer minutesPerSession, PlanStatus status,
                                    @Size(max = 1000) String notes) {
        public WeeklyTrainingPlan.Values toValues() {
            return new WeeklyTrainingPlan.Values(plannedSessions, intensity, minutesPerSession, status, notes);
        }
    }

    /** Plan con las sesiones completadas esa semana y el cumplimiento (0-1). */
    public record WeeklyPlanResponse(UUID id, LocalDate weekStart, int plannedSessions, PlanIntensity intensity,
                                     int minutesPerSession, PlanStatus status, String notes, int completedSessions,
                                     double compliance) {
        public static WeeklyPlanResponse from(WeeklyPlanProgress p) {
            WeeklyTrainingPlan plan = p.plan();
            return new WeeklyPlanResponse(plan.id(), plan.weekStart(), plan.plannedSessions(), plan.intensity(),
                    plan.minutesPerSession(), plan.status(), plan.notes(), p.completedSessions(), p.compliance());
        }
    }
}
