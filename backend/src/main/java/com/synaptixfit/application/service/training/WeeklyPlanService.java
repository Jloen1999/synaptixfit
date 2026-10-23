package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.DeleteWeeklyPlanUseCase;
import com.synaptixfit.application.port.input.training.GetWeeklyPlanUseCase;
import com.synaptixfit.application.port.input.training.ListWeeklyPlansUseCase;
import com.synaptixfit.application.port.input.training.SaveWeeklyPlanUseCase;
import com.synaptixfit.application.port.input.training.WeeklyPlanProgress;
import com.synaptixfit.domain.exception.training.WeeklyPlanNotFoundException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.WeeklyTrainingPlan;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import com.synaptixfit.domain.port.output.training.WeeklyPlanRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Plan semanal de entrenamiento (uno por semana, identificada por su lunes) y su cumplimiento. */
public class WeeklyPlanService implements SaveWeeklyPlanUseCase, GetWeeklyPlanUseCase, ListWeeklyPlansUseCase,
        DeleteWeeklyPlanUseCase {

    private final WeeklyPlanRepositoryPort plans;
    private final TrainingSessionRepositoryPort sessions;
    private final Clock clock;

    public WeeklyPlanService(WeeklyPlanRepositoryPort plans, TrainingSessionRepositoryPort sessions, Clock clock) {
        this.plans = plans;
        this.sessions = sessions;
        this.clock = clock;
    }

    @Override
    public WeeklyPlanProgress save(UUID userId, LocalDate weekStart, WeeklyTrainingPlan.Values values) {
        LocalDate monday = WeeklyTrainingPlan.mondayOf(Guard.notNull(weekStart, "weekStart"));
        WeeklyTrainingPlan plan = plans.findByUserAndWeek(userId, monday)
                .map(existing -> {
                    existing.apply(values);
                    return existing;
                })
                .orElseGet(() -> WeeklyTrainingPlan.create(userId, monday, values));
        return progress(plans.save(plan));
    }

    @Override
    public WeeklyPlanProgress get(UUID userId, LocalDate weekStart) {
        LocalDate monday = WeeklyTrainingPlan.mondayOf(Guard.notNull(weekStart, "weekStart"));
        return progress(plans.findByUserAndWeek(userId, monday)
                .orElseThrow(() -> new WeeklyPlanNotFoundException(monday)));
    }

    @Override
    public PageResult<WeeklyPlanProgress> list(UUID userId, PageRequest page) {
        return plans.findByUser(userId, page).map(this::progress);
    }

    @Override
    public void delete(UUID userId, LocalDate weekStart) {
        LocalDate monday = WeeklyTrainingPlan.mondayOf(Guard.notNull(weekStart, "weekStart"));
        WeeklyTrainingPlan plan = plans.findByUserAndWeek(userId, monday)
                .orElseThrow(() -> new WeeklyPlanNotFoundException(monday));
        plans.delete(plan.id());
    }

    private WeeklyPlanProgress progress(WeeklyTrainingPlan plan) {
        Instant from = plan.weekStart().atStartOfDay(clock.getZone()).toInstant();
        Instant to = plan.weekStart().plusDays(7).atStartOfDay(clock.getZone()).toInstant();
        return new WeeklyPlanProgress(plan, sessions.countCompletedBetween(plan.userId(), from, to));
    }
}
